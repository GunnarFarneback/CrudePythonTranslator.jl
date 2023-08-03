using Test, CrudePythonTranslator

include("utils.jl")
include("translate.jl")
include("base.jl")
clear_rules_coverage()
include("library.jl")
@testset "Rules coverage and docstrings" begin
    check_rules_coverage_and_docstrings()
end
