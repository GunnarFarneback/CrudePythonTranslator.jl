using CrudePythonTranslator.Library

@testset "Library translations" begin
    for filename in readdir(joinpath(@__DIR__, "data", "library"), join = true)
        endswith(filename, ".py") || continue
        rule_name = first(splitext(basename(filename)))
        rule = getfield(CrudePythonTranslator.Library, Symbol(rule_name))
        @test check_translation(filename, rule)
    end
end
