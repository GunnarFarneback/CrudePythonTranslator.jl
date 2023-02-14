module CrudePythonTranslator

using Multibreak: @multibreak

export translate, Map, InPlace, Rule

struct Map
    f::Any
end

(m::Map)(tokens) = (map!(m.f, tokens, tokens); tokens)

struct InPlace
    f!::Any
end

(i::InPlace)(tokens) = (i.f!(tokens); tokens)

struct Rule
    from::Vector{Any}
    to::Vector{Any}
end

@multibreak function (rule::Rule)(tokens)
    matches = []
    for n = length(tokens):-1:1
        i = n
        for from_token in reverse(rule.from)
            i < 1 && break; continue
            optional = false
            if from_token isa Vector
                from_token = only(from_token)
                optional = true
            end
            from_name, from_text = from_token
            name, text = tokens[i]
            if ismatch(from_text, text, matches) && ismatch(from_name, name, matches)
                i -= 1
            else
                if optional
                    continue
                else
                    break; continue
                end
            end
        end
        i += 1
        for j = n:-1:i
            deleteat!(tokens, j)
        end
        for to_token in reverse(rule.to)
            insert!(tokens, i, replace_match.(to_token, Ref(matches)))
        end
    end
    return tokens
end

function ismatch(r::Regex, s::AbstractString, matches)
    if occursin(r, s)
        pushfirst!(matches, s)
        return true
    end
    pushfirst!(matches, "")
    return false
end

ismatch(r, s, _) = (r == s)

replace_match(i::Integer, matches) = matches[i]

replace_match(s, _) = s

function preprocess_tokens(py, tokenize)
    token_codes = tokenize.tok_name
    indent_stack = String[]
    current_indent = ""
    last_line = 0
    last_col = 0
    jl = Tuple{String, String}[]
    for (i, token) in enumerate(py)
        code, text, (start_line, start_col), (end_line, end_col), full = token
        full_indices = collect(eachindex(full))
        if code == tokenize.NL
        elseif start_line > last_line || code == tokenize.DEDENT && first(py[i - 1]) == tokenize.DEDENT
            if code == tokenize.INDENT
                push!(indent_stack, current_indent)
                current_indent = text
            elseif code == tokenize.DEDENT
                current_indent = pop!(indent_stack)
            end
            if code == tokenize.INDENT || code == tokenize.DEDENT || length(current_indent) <= start_col
                push!(jl, ("INDENT", current_indent))
            else
                push!(jl, ("INDENT", current_indent[1:start_col]))
            end
            if code == tokenize.DEDENT
                next_code, next_text = py[i + 1]
                if next_code != tokenize.NAME || next_text ∉ ("elif", "else", "except", "finally")
                    push!(jl, ("END", "end"))
                    push!(jl, ("NEWLINE", "\n"))
                    if next_code != tokenize.DEDENT
                        push!(jl, ("INDENT", current_indent))
                    end
                end
            end
            if start_col > length(current_indent)
                push!(jl, ("SPACE", full[full_indices[length(current_indent) + 1]:full_indices[start_col]]))
            end
        elseif start_col > last_col
            push!(jl, ("SPACE", full[full_indices[last_col + 1]:full_indices[start_col]]))
        end
        if code ∉ (tokenize.INDENT, tokenize.DEDENT)
            push!(jl, (get(token_codes, code, "UNKNOWN_TOKEN"), text))
        end
        last_line, last_col = end_line, end_col
    end
    return jl
end

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

standard_translations = [Map(normalize_string),
                         InPlace(convert_keywords!),
                         remove_colon_rule1,
                         remove_colon_rule2,
                         remove_colon_rule3,
                         InPlace(convert_ops!),
                         InPlace(adjust_end_positions!),
                         InPlace(move_docstrings!),
                         InPlace(fix_function_arg_alignment!),
                         is_none_rule,
                         is_not_none_rule,
                         not_in_rule,
                         not_rule]

function remove_CR(token)
    name, text = token
    return name, replace(text, "\r\n" => "\n")
end

function add_CR(token)
    name, text = token
    return name, replace(text, "\n" => "\r\n")
end

function translate_file(python_file, julia_file, tokenize, translations,
                        verbose)
    @assert endswith(python_file, ".py")
    @assert endswith(julia_file, ".jl")

    py_tokens = open(python_file, "r") do f
        file_source = () -> readline(f, keep = true)
        collect(tokenize.generate_tokens(file_source))
    end

    tokens = preprocess_tokens(py_tokens, tokenize)

    if Sys.iswindows()
        map!(remove_CR, tokens, tokens)
    end

    for translate in translations
        tokens = translate(tokens)
    end

    if Sys.iswindows()
        map!(add_CR, tokens, tokens)
    end

    if verbose
        for (name, text) in tokens
            println(rpad(name, 20), "\"", escape_string(text), "\"")
        end
    end

    write(julia_file, reduce(*, last.(tokens)))
end

"""
    translate(filename; kwargs...)

Translate `filename`, which must be a Python file with `.py`
extension. The output is written to the same path with `.py` replaced
by `.jl`, if this does not yet exist, otherwise with extension
`.crude.jl`.

    translate(dirname; kwargs...)

Translate all python files in the directory `dirname`.

    translate(source, custom_translations...; kwargs...)
    translate(source, custom_translations::Vector; kwargs...)

Translate file or directory `source` with additional
`custom_translations`. A custom translation is a function which
receives a vector of tokens and returns a possibly modified vector of
tokens.

*keyword arguments:*

* `recursive`: When the source is a directory, translate files also in
  all subdirectories, recursively. Defaults to `false`.

* `overwrite`: If the output `.jl` file already exists, overwrite it
  instead of writing to `.crude.jl` file. Defaults to `false`.

* `pyimport`: The `pyimport` function from either the `PyCall` or the
  `PythonCall` package. *This is a mandatory keyword.*

* `include_standard_translations`: If `false`, only do a minimal
  translation. Defaults to true. This can be used if you want to do a
  fully customized translation.

* `verbose`: If `true`, print the output sequence of tokens. Defaults
  to `false`. Mostly useful with a single short file to figure out how
  to design a custom translation function.
"""
function translate(source, custom_translations...; kwargs...)
    translate(source, [custom_translations...]; kwargs...)
end

function translate(source, custom_translations::Vector;
                   recursive = false, overwrite = false, pyimport = nothing,
                   include_standard_translations = true, verbose = false)
    if isnothing(pyimport)
        error("`pyimport` is a mandatory keyword argument.")
    end

    python_files = String[]
    if isfile(source)
        endswith(source, ".py") || error("File extension must be .py")
        push!(python_files, source)
    elseif isdir(source)
        if recursive
            for (root, dirs, files) in walkdir(source)
                for file in files
                    if endswith(file, ".py")
                        push!(python_files, joinpath(root, file))
                    end
                end
            end
        else
            append!(python_files, filter(endswith(".py"),
                                  readdir(source, join = true)))
        end
    else
        error("`source` must be either a directory or a python file.")
    end

    if isempty(python_files)
        warn("No python files found in `source` path.")
        return
    end

    tokenize = pyimport("tokenize")

    translations = []
    if include_standard_translations
        append!(translations, standard_translations)
    end
    append!(translations, custom_translations)

    for python_file in python_files
        base, ext = splitext(python_file)
        @assert ext == ".py"
        julia_file = "$(base).jl"
        if isfile(julia_file) && !overwrite
            julia_file = "$(base).crude.jl"
        end
        translate_file(python_file, julia_file, tokenize, translations, verbose)
    end
end

end
