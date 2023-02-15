export base_translations

function normalize_string(token)
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

function convert_keywords!(tokens)
    for (i, (code, text)) in enumerate(tokens)
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
                    end
                end
            end
            tokens[i] = (code, text)
        end
    end
end

remove_colon_rule1 = Rule([("OP", ":"), ("NEWLINE", "\n")],
                          [("NEWLINE", "\n")])
remove_colon_rule2 = Rule([("OP", ":"), ("COMMENT", r".*"), ("NEWLINE", "\n")],
                          [("COMMENT", 1), ("NEWLINE", "\n")])
remove_colon_rule3 = Rule([("OP", ":"), ("SPACE", r".*"),
                           ("COMMENT", r".*"), ("NEWLINE", "\n")],
                          [("SPACE", 1), ("COMMENT", 2), ("NEWLINE", "\n")])
remove_colon = Sequence([remove_colon_rule1,
                         remove_colon_rule2,
                         remove_colon_rule3])

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

is_none_rule = Rule([("NAME", r".*"), ("SPACE", r".*"), ("NAME", "is"),
                     ("SPACE", r".*"), ("NAME", "None")],
                    [("NAME", "isnothing"), ("OP", "("),
                     ("NAME", 1), ("OP", ")")])

is_not_none_rule = Rule([("NAME", r".*"), ("SPACE", r".*"), ("NAME", "is"),
                         ("SPACE", r".*"), ("NAME", "not"), ("SPACE", r".*"),
                         ("NAME", "None")],
                        [("OP", "!"), ("NAME", "isnothing"), ("OP", "("),
                         ("NAME", 1), ("OP", ")")])

not_in_rule = Rule([("NAME", "not"), ("SPACE", r".*"), ("NAME", "in")],
                   [("OP", "∉")])

not_rule = Rule([("NAME", "not"), ("SPACE", r".*")],
                [("OP", "!")])

base_translations = Sequence([Map(normalize_string),
                              InPlace(convert_keywords!),
                              remove_colon,
                              InPlace(convert_ops!),
                              InPlace(adjust_end_positions!),
                              InPlace(move_docstrings!),
                              InPlace(fix_function_arg_alignment!),
                              is_none_rule,
                              is_not_none_rule,
                              not_in_rule,
                              not_rule])
