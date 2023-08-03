# Convert `@assert` to `@test`. Assumes that `assert` has previously
# been converted to `@assert`.
function assert_to_test!(tokens)
    for i in reverse(eachindex(tokens))
        token = tokens[i]
        if i > 1 && token == ("NAME", "assert") && tokens[i - 1] == ("OP", "@")
            tokens[i] = ("NAME", "test")
            j = i
            while j < length(tokens) && tokens[j] != ("NEWLINE", "\n")
                j += 1
            end
            if tokens[j] == ("NEWLINE", "\n")
                if (first(tokens[j - 1]) == "STRING"
                    && first(tokens[j - 2]) == "SPACE"
                    && tokens[j - 3] == ("OP", ","))

                    deleteat!(tokens, j - 1)
                    deleteat!(tokens, j - 2)
                    deleteat!(tokens, j - 3)
                end
            end
        end
    end
    return false
end

# Converts a function with a name of the form `test_*` to a
# correspondingly named `@testset`.
function make_testset!(tokens)
    for (i, token) in enumerate(tokens)
        if token == ("NAME", "function")
            name, text = tokens[i + 2]
            if name == "NAME" && startswith(text, "test_")
                tokens[i] = ("NAME", "@testset")
                testset_name = replace(text[6:end], "_" => " ")
                tokens[i + 2] = ("STRING", "\"$(testset_name)\"")
                i += 3
                while tokens[i] != ("OP", ")")
                    deleteat!(tokens, i)
                end
                tokens[i] = ("SPACE", " ")
                insert!(tokens, i + 1, ("NAME", "begin"))
                return true
            end
        end
    end
    return false
end

# Converts a `pytest.raises` to `@test_throws`.
function pytest_raises!(tokens)
    for i = (length(tokens) - 9):-1:1
        if (tokens[i] == ("NAME", "with")
            && first(tokens[i + 1]) == "SPACE"
            && tokens[i + 2] == ("NAME", "pytest")
            && tokens[i + 3] == ("OP", ".")
            && tokens[i + 4] == ("NAME", "raises")
            && tokens[i + 5] == ("OP", "(")
            && first(tokens[i + 6]) == "NAME"
            && tokens[i + 7] == ("OP", ")")
            && tokens[i + 8] == ("NEWLINE", "\n")
            && first(tokens[i + 9]) == "INDENT")

            j = i + 10
            while j <= length(tokens) && tokens[j] != ("END", "end")
                j += 1
            end
            j > length(tokens) && continue
            if first(tokens[j - 1]) == "INDENT" && tokens[j - 2] == ("NEWLINE", "\n")
                deleteat!(tokens, j)
                deleteat!(tokens, j - 1)
                deleteat!(tokens, j - 2)
                deleteat!(tokens, i + 9)
                deleteat!(tokens, i + 8)
                tokens[i + 7] = ("SPACE", " ")
                tokens[i + 5] = ("SPACE", " ")
                deleteat!(tokens, i + 4)
                deleteat!(tokens, i + 3)
                deleteat!(tokens, i + 2)
                tokens[i + 1] = ("NAME", "test_throws")
                tokens[i] = ("OP", "@")
            end
        end
    end
end

const assert_to_test = InPlace(assert_to_test!)
const make_testset = IteratedInPlace(make_testset!)
const pytest_raises = InPlace(pytest_raises!)

const pytest = Sequence([assert_to_test, make_testset, pytest_raises])
