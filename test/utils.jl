using CrudePythonTranslator: TranslationRule

function find_python_data_files(data_path)
    return filter(endswith(".py"),
                  readdir(joinpath(@__DIR__, "data", data_path), join = true))
end

function get_rules_from_module(m)
    return Dict(string(name) => getfield(m, name)
                for name in names(m, all = true)
                if getfield(m, name) isa TranslationRule)
end

# Expand a list of rules with the elements of present Sequences,
# recursively, unless those rules are already in the list. Keep the
# expanded Sequences in the list.
function expand_sequences(rules)
    expanded = IdDict{TranslationRule, String}(rule => name
                                               for (name, rule) in rules)
    sequences = [name => rule
                 for (name, rule) in rules
                 if rule isa Sequence]
    while !isempty(sequences)
        name, rule = popfirst!(sequences)
        for (i, rule2) in enumerate(rule.f)
            haskey(expanded, rule2) && continue
            expanded[rule2] = "$name[$i]"
            if rule2 isa Sequence
                push!(sequences, "$name[$i]" => rule2)
            end
        end
    end
    return Dict{String, TranslationRule}(name => rule
                                         for (rule, name) in expanded)
end

const rules_coverage = Set{TranslationRule}()

clear_rules_coverage() = empty!(rules_coverage)

function check_translation(python_path, args...; kwargs...)
    @assert endswith(python_path, ".py")
    mktempdir() do tmp_dir
        julia_path = replace(python_path, ".py" => ".jl")
        python_tmp_path = joinpath(tmp_dir, last(splitdir(python_path)))
        julia_tmp_path = joinpath(tmp_dir, last(splitdir(julia_path)))
        cp(python_path, python_tmp_path)
        translate(python_tmp_path, args...; kwargs...)
        expected = read(julia_path, String)
        translated = read(julia_tmp_path, String)
        success = expected == translated
        if !success
            println("Translation failure for ", python_path)
            println("--- Translation ---\n", translated)
            println("--- Expected ---\n", expected)
        end

        # If called with a single rule, check whether it had some
        # effect.
        if length(args) == 1
            translate(python_tmp_path; overwrite = true, kwargs...)
            base_translated = read(julia_tmp_path, String)
            for rule in values(expand_sequences(Dict("" => only(args))))
                translate(python_tmp_path, rule; overwrite = true, kwargs...)
                translated = read(julia_tmp_path, String)
                if translated != base_translated
                    push!(rules_coverage, rule)
                end
            end
        end

        return success
    end
end

function check_rules_coverage_and_docstrings()
    base_rules = get_rules_from_module(CrudePythonTranslator)
    library_rules = get_rules_from_module(CrudePythonTranslator.Library)
    # Check that all library rules have had an effect on some
    # translation. (Coverage of base rules is checked separately in
    # `test/base.jl`.)
    not_covered_rules = [name
                         for (name, rule) in expand_sequences(library_rules)
                         if rule ∉ rules_coverage]
    if !isempty(not_covered_rules)
        println("The following library rules have not been tested or are not effective:")
        printstyled(join(not_covered_rules, ", "), "\n", color = :red)
    end
    @test isempty(not_covered_rules)

    # Check that all rules have documentation, unless starting with underscore.
    missing_docs = String[]
    for (name, rule) in merge(base_rules, library_rules)
        if !startswith(name, "_") && isempty(rule.doc)
            push!(missing_docs, name)
        end
    end
    if !isempty(missing_docs)
        println("The following rules do not have documentation:")
        printstyled(join(missing_docs, ", "), "\n", color = :red)
    end
    @test isempty(missing_docs)
end
