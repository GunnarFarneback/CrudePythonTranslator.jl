export base_translations

function _normalize_string(token)
    code, text = token
    if code == "STRING"
        prefix = ""
        if isletter(first(text))
            prefix = first(text)
            text = text[2:end]
        end
        if startswith(text, "'''")
            text = replace(text, "\"" => "\\\"")
            text = replace(text, "'''" => "\"\"\"")
        elseif startswith(text, "'")
            text = replace(text, "\"" => "\\\"")
            text = replace(text, "'" => "\"")
        end
        text = prefix * text
    end
    return code, text
end

const normalize_string = Map(_normalize_string)

# If the Python file did not have a final newline and ended with an
# indented line, there will be a ("NEWLINE", "") token preceding one
# or more END tokens. Move the "empty newline token" to the end if
# that's the case.
function no_final_newline!(tokens)
    empty_newline_found = false
    last_newline = 0
    for (i, token) in enumerate(tokens)
        if first(token) == "NEWLINE"
            last_newline = i
            if last(token) == ""
                tokens[i] = ("NEWLINE", "\n")
                empty_newline_found = true
            end
        end
    end
    if empty_newline_found
        tokens[last_newline] = ("NEWLINE", "")
    end
end

const no_final_newline = InPlace(no_final_newline!)

function convert_keywords!(tokens)
    for i in reverse(eachindex(tokens))
        code, text = tokens[i]
        if code == "NAME" && (i <= 1 || tokens[i - 1] != ("OP", "."))
            for (from, to) in ["True" => "true",
                               "False" => "false",
                               "def" => "function",
                               "elif" => "elseif",
                               "or" => "||",
                               "and" => "&&",
                               "assert" => "@assert"]
                if text == from
                    text = to
                    if from in ("or", "and")
                        code = "OP"
                    elseif to == "@assert"
                        insert!(tokens, i + 1, ("NAME", "assert"))
                        code = "OP"
                        text = "@"
                    end
                    break
                end
            end
            tokens[i] = (code, text)
        end
    end
end

const convert_keywords = InPlace(convert_keywords!)

const _remove_colon_rule1 = Rule([("OP", ":"), ("NEWLINE", "\n")],
                                 [("NEWLINE", "\n")])
const _remove_colon_rule2 = Rule([("OP", ":"), ("COMMENT", r".*"),
                                  ("NEWLINE", "\n")],
                                 [("COMMENT", 1), ("NEWLINE", "\n")])
const _remove_colon_rule3 = Rule([("OP", ":"), ("SPACE", r".*"),
                                  ("COMMENT", r".*"), ("NEWLINE", "\n")],
                                 [("SPACE", 1), ("COMMENT", 2),
                                  ("NEWLINE", "\n")])
const remove_colon = Sequence([_remove_colon_rule1,
                               _remove_colon_rule2,
                               _remove_colon_rule3])

function convert_ops!(tokens)
    for (i, token) in enumerate(tokens)
        if token == ("OP", "**")
            j = i - 1
            if first(tokens[j]) == "SPACE"
                j -= 1
            end
            if tokens[j] ∉ [("OP", "("), ("OP", ",")]
                tokens[i] = ("OP", "^")
            end
        elseif token == ("OP", "//")
            tokens[i] = ("OP", "÷")
        end
    end
end

const convert_ops = InPlace(convert_ops!)

function adjust_end_positions!(tokens)
    something_changed = true
    while something_changed
        something_changed = false
        for i in length(tokens):-1:5
            if i > 5 && first.(tokens[(i - 5):i]) == ["INDENT", "COMMENT", "NL", "INDENT", "END", "NEWLINE"]
                if length(last(tokens[i - 5])) <= length(last(tokens[i - 2]))
                    tokens[(i - 5):i] = tokens[[(i - 2):i; (i - 5):(i - 3)]]
                    something_changed = true
                end
            elseif first.(tokens[(i - 4):i]) == ["NL", "NL", "INDENT", "END", "NEWLINE"]
                tokens[(i - 3):i] = tokens[[(i - 2):i; i - 3]]
                something_changed = true
            elseif first.(tokens[(i - 4):i]) == ["NEWLINE", "NL", "INDENT", "END", "NEWLINE"]
                tokens[(i - 3):i] = tokens[[(i - 2):i; i - 3]]
                something_changed = true
            end
        end
    end
end

const adjust_end_positions = InPlace(adjust_end_positions!)

function move_docstrings!(tokens)
    for i in findall(==(("NAME", "function")), tokens)
        j = i
        while tokens[j] != ("NEWLINE", "\n")
            j += 1
        end
        if first.(tokens[(j + 1):(j + 3)]) == ["INDENT", "STRING", "NEWLINE"]
            tokens[j + 1] = ("INDENT", "")
            docstring = last(tokens[j + 2])
            tokens[j + 2] = ("STRING", replace(docstring, "\n    " => "\n"))
            tokens[i:(j + 3)] = tokens[[(j + 1):(j + 3); i:j]]
        end
    end
end

const move_docstrings = InPlace(move_docstrings!)

function fix_function_arg_alignment!(tokens)
    for i in findall(==(("NAME", "function")), tokens)
        j = i
        while tokens[j] != ("NEWLINE", "\n")
            if first.(tokens[j:(j + 2)]) == ["NL", "INDENT", "SPACE"]
                tokens[j + 2] = ("SPACE", last(tokens[j + 2]) * "     ")
            end
            j += 1
        end
    end
end

const fix_function_arg_alignment = InPlace(fix_function_arg_alignment!)

const is_none = Rule([("NAME", r".*"), ("SPACE", r".*"), ("NAME", "is"),
                      ("SPACE", r".*"), ("NAME", "None")],
                     [("NAME", "isnothing"), ("OP", "("),
                      ("NAME", 1), ("OP", ")")])

const is_not_none = Rule([("NAME", r".*"), ("SPACE", r".*"),
                          ("NAME", "is"),  ("SPACE", r".*"),
                          ("NAME", "not"), ("SPACE", r".*"),
                          ("NAME", "None")],
                         [("OP", "!"), ("NAME", "isnothing"),
                          ("OP", "("), ("NAME", 1), ("OP", ")")])

const not_in = Rule([("NAME", "not"), ("SPACE", r".*"), ("NAME", "in")],
                    [("OP", "∉")])

const not_rule = Rule([("NAME", "not"), ("SPACE", r".*")],
                      [("OP", "!")])

const none_rule = simple_rule("None", "nothing")

const _empty_dict = simple_rule("{}", "Dict()")

function dict_and_set!(tokens)
    i = 1
    while i < length(tokens)
        if tokens[i] != ("OP", "{")
            i += 1
            continue
        end
        colons = Int[]
        count = 0
        n = i
        while n in eachindex(tokens)
            if tokens[n] == ("OP", "{")
                count += 1
            elseif tokens[n] == ("OP", "}")
                count -= 1
                count == 0 && break
            elseif count == 1 && tokens[n] == ("OP", ":")
                push!(colons, n)
            end
            n += 1
        end

        tokens[n] = ("OP", ")")
        for j in reverse(colons)
            tokens[j] = ("OP", "=>")
            if first(tokens[j - 1]) != "SPACE"
                insert!(tokens, j, ("SPACE", " "))
            end
        end
        tokens[i] = ("OP", "(")
        insert!(tokens, i, ("NAME", isempty(colons) ? "Set" : "Dict"))
        i += 1
    end
end

const dict_and_set = Sequence([_empty_dict, InPlace(dict_and_set!)])

const base_translations = Sequence([normalize_string,
                                    no_final_newline,
                                    convert_keywords,
                                    remove_colon,
                                    convert_ops,
                                    adjust_end_positions,
                                    move_docstrings,
                                    fix_function_arg_alignment,
                                    is_none,
                                    is_not_none,
                                    not_in,
                                    not_rule,
                                    none_rule,
                                    dict_and_set])
