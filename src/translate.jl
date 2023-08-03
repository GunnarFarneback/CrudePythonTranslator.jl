export translate

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

function remove_CR(token)
    name, text = token
    return name, replace(text, "\r\n" => "\n")
end

function add_CR(token)
    name, text = token
    return name, replace(text, "\n" => "\r\n")
end

# Translate a single file. This is called by `translate` for each file
# to be translated.
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

    for translation_rule in translations
        tokens = translation_rule(tokens)
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

* `include_base_translations`: If `false`, only do a minimal
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
                   recursive = false, overwrite = false,
                   include_base_translations = true, verbose = false)
    python_files = String[]
    if isfile(source)
        endswith(source, ".py") || error("File extension must be .py")
        recursive && error("Cannot translate a single file recursively.")
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
        @warn("No python files found in `source` path.")
        return
    end

    tokenize = pyimport("tokenize")

    translations = []
    if include_base_translations
        push!(translations, base_translations)
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
