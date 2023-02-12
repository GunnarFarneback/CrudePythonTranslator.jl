using Test, PyCall, CrudePythonTranslator

@testset "Standard use" begin
    data_dir = joinpath(@__DIR__, "data")
    tmp_dir = mktempdir()
    filenames = filter(endswith(".py"), readdir(data_dir))
    for filename in sort(filenames,
                         by = name -> parse(Int, first(splitext(name))))
        julia_filename = replace(filename, ".py" => ".jl")
        cp(joinpath(data_dir, filename), joinpath(tmp_dir, filename))
        translate(joinpath(tmp_dir, filename); pyimport)
        expected = read(joinpath(data_dir, julia_filename), String)
        translated = read(joinpath(tmp_dir, julia_filename), String)
        expected == translated || println("Translation failure for $filename")
        @test expected == translated
    end
end
