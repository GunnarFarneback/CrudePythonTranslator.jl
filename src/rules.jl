export Map, InPlace, IteratedInPlace, Sequence, Rule, simple_rule

struct Map
    f::Any
end

(m::Map)(tokens) = (map!(m.f, tokens, tokens); tokens)

struct InPlace
    f!::Any
end

(i::InPlace)(tokens) = (i.f!(tokens); tokens)

struct IteratedInPlace
    f!::Any
end

function (i::IteratedInPlace)(tokens)
    while i.f!(tokens)
    end
    return tokens
end

struct Sequence
    f::Vector{Any}
end

(s::Sequence)(tokens) = foldl(|>, s.f, init = tokens)

struct Rule
    from::Vector{Any}
    to::Vector{Any}
    replace_opening::Union{Nothing, Vector{Any}}
    replace_closing::Union{Nothing, Vector{Any}}
    Rule(from, to; replace_opening = nothing, replace_closing = nothing) =
        new(from, to, replace_opening, replace_closing)
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

        if (!isnothing(rule.replace_closing) != 0
            && last(last(rule.from)) in ("(", "[", "{"))

            m = find_matching_delimiter(tokens, n)
            if m > 0
                deleteat!(tokens, m)
                for replace_token in reverse(rule.replace_closing)
                    insert!(tokens, m, replace_match.(replace_token, Ref(matches)))
                end
            end
        end

        matching_opener = 0
        if (!isnothing(rule.replace_opening) != 0
            && last(first(rule.from)) in (")", "]", "}"))
            matching_opener = find_matching_delimiter(tokens, i)
        end

        for j = n:-1:i
            deleteat!(tokens, j)
        end

        for to_token in reverse(rule.to)
            insert!(tokens, i, replace_match.(to_token, Ref(matches)))
        end

        if matching_opener > 0
            m = matching_opener
            deleteat!(tokens, m)
            for replace_token in reverse(rule.replace_opening)
                insert!(tokens, m, replace_match.(replace_token, Ref(matches)))
            end
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

function find_matching_delimiter(tokens, n)
    _, source = tokens[n]
    target, direction = Dict("(" => (")", 1),
                             "[" => ("]", 1),
                             "{" => ("}", 1),
                             ")" => ("(", -1),
                             "]" => ("[", -1),
                             "}" => ("{", -1))[source]

    count = 0
    while n in eachindex(tokens)
        if tokens[n] == ("OP", source)
            count += 1
        elseif tokens[n] == ("OP", target)
            count -= 1
        end
        if count == 0
            return n
        end
        n += direction
    end

    return 0
end

function simple_rule(from, to;
                     replace_opening = nothing, replace_closing = nothing)
    return Rule(crude_tokenize(from), crude_tokenize(to),
                replace_opening = crude_tokenize(replace_opening),
                replace_closing = crude_tokenize(replace_closing))
end

crude_tokenize(::Nothing) = nothing
crude_tokenize(text::AbstractString) = crude_tokenize(split_tokens(text))
crude_tokenize(texts::Vector) = auto_token.(texts)

@multibreak function split_tokens(text)
    number_re = r"^((0x[0-9a-f]+)|(0b[01]+)|(0[0-7]*)|(((?!0)|[-+]|(?=0+\.))(\d*\.)?\d+((e|f)[-+]?\d+)?))((.|\s)*)"
    name_re = r"^(\w+)((.|\s)*)"
    space_re = r"^(\s+)((.|\s)*)"
    # Only need multicharacter operators in here, but should cover
    # both Python and Julia.
    op_re = r"^(===|!==|==|!=|%=|&=|\*=|\*\*|\*\*=|\+=|-=|->|=>|\.\.\.|\.=|//|//=|/=|:=|<<|<<=|<=|>>|>>=|>=|@=|\^=|\|=|÷=|\$=|\\=)((.|\s)*)"
    tokens = []
    while !isempty(text)
        if first(text) == '\n'
            push!(tokens, "\n")
            text = text[2:end]
            continue
        end
        for re in (space_re, number_re, name_re, op_re)
            matches = match(re, text)
            if !isnothing(matches)
                push!(tokens, first(matches.captures))
                text = matches.captures[end - 1]
                break; continue
            end
        end
        push!(tokens, string(first(text)))
        text = text[nextind(text, 1):end]
    end
    return tokens
end

auto_token(text) = (guess_type(text), text)

function guess_type(text)
    isdigit(first(text)) && return "NUMBER"
    isletter(first(text)) && return "NAME"
    isspace(first(text)) && return "SPACE"
    first(text) == '\n' && return "NEWLINE"
    return "OP"
end
