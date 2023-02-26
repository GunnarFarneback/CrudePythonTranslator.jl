@testset "Base translations" begin
    for filename in find_python_data_files("base")
        @test check_translation(filename)
    end
end
