@testset "Base translations" begin
    for filename in find_python_data_files("base")
        @test check_translation(filename)
    end
end

# Check that each individual base rule does *something* to at least
# one of the data files.
@testset "Base translations rule coverage" begin
    base_rules = get_rules_from_module(CrudePythonTranslator)
    effective_rules = Set{String}()
    for python_path in find_python_data_files("base")
        mktempdir() do tmp_dir
            julia_path = replace(python_path, ".py" => ".jl")
            python_tmp_path = joinpath(tmp_dir, last(splitdir(python_path)))
            julia_tmp_path = joinpath(tmp_dir, last(splitdir(julia_path)))
            cp(python_path, python_tmp_path)
            translate(python_tmp_path, include_base_translations = false)
            base_translation = read(julia_tmp_path, String)
            # Some base rules are only effective if `def` has already
            # been converted to `function`, so add a second baseline
            # with that applied.
            translate(python_tmp_path, CrudePythonTranslator.convert_keywords,
                      include_base_translations = false, overwrite = true)
            base_translation2 = read(julia_tmp_path, String)
            for (name, rule) in base_rules
                translate(python_tmp_path, rule,
                          include_base_translations = false, overwrite = true)
                rule_translation = read(julia_tmp_path, String)
                if base_translation != rule_translation
                    push!(effective_rules, name)
                end

                translate(python_tmp_path,
                          CrudePythonTranslator.convert_keywords, rule,
                          include_base_translations = false, overwrite = true)
                rule_translation2 = read(julia_tmp_path, String)
                if base_translation2 != rule_translation2
                    push!(effective_rules, name)
                end
            end
        end
    end
    ineffective_rules = setdiff(keys(base_rules), effective_rules)
    if !isempty(ineffective_rules)
        println("The following base rules have not been tested or are not effective:")
        printstyled(join(ineffective_rules, ", "), "\n", color = :red)
    end
    @test Set(keys(base_rules)) == effective_rules
end
