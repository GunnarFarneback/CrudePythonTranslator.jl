@testset "Translate single file" begin
    mktempdir() do tmp_dir
        mkdir(joinpath(tmp_dir, "subdir"))
        python_paths = find_python_data_files("base")
        tmp_python_paths = joinpath.(tmp_dir,
                                     [".", ".", "subdir", "subdir"],
                                     last.(splitdir.(python_paths[1:4])))
        # Cannot translate non-existing file.
        @test_throws ErrorException translate(tmp_python_paths[1])
        cp.(python_paths[1:4], tmp_python_paths)
        translate(tmp_python_paths[1])
        @test count(endswith(".jl"), readdir(tmp_dir)) == 1
        @test count(endswith(".jl"), readdir(joinpath(tmp_dir, "subdir"))) == 0
        expected = read(replace(python_paths[1], ".py" => ".jl"), String)
        tmp_julia_path = replace(tmp_python_paths[1], ".py" => ".jl")
        translated = read(tmp_julia_path, String)
        @test expected == translated
        # Cannot use `recursive` with a file.
        @test_throws ErrorException translate(tmp_python_paths[1],
                                              recursive = true)
        # Cannot translate non-Python files.
        @test_throws ErrorException translate(tmp_julia_path)

        # Do not overwrite existing file.
        write(tmp_julia_path, "something else")
        translate(tmp_python_paths[1])
        @test read(tmp_julia_path, String) == "something else"
        crude_julia_path = replace(tmp_julia_path, ".jl" => ".crude.jl")
        translated = read(crude_julia_path, String)
        @test expected == translated

        # Do overwrite existing file.
        rm(crude_julia_path)
        translate(tmp_python_paths[1], overwrite = true)
        translated = read(tmp_julia_path, String)
        @test expected == translated
        @test !isfile(crude_julia_path)
    end
end

@testset "Translate single directory" begin
    mktempdir() do tmp_dir
        mkdir(joinpath(tmp_dir, "subdir"))
        python_paths = find_python_data_files("base")
        tmp_python_paths = joinpath.(tmp_dir,
                                     [".", ".", "subdir", "subdir"],
                                     last.(splitdir.(python_paths[1:4])))
        cp.(python_paths[1:4], tmp_python_paths)
        translate(tmp_dir)
        @test count(endswith(".jl"), readdir(tmp_dir)) == 2
        @test count(endswith(".jl"), readdir(joinpath(tmp_dir, "subdir"))) == 0
        for i = 1:2
            expected = read(replace(python_paths[i], ".py" => ".jl"), String)
            translated = read(replace(tmp_python_paths[i], ".py" => ".jl"), String)
            @test expected == translated
        end
    end
end

@testset "Translate directories recursively" begin
    mktempdir() do tmp_dir
        mkdir(joinpath(tmp_dir, "subdir"))
        python_paths = find_python_data_files("base")
        tmp_python_paths = joinpath.(tmp_dir,
                                     [".", ".", "subdir", "subdir"],
                                     last.(splitdir.(python_paths[1:4])))
        cp.(python_paths[1:4], tmp_python_paths)
        translate(tmp_dir, recursive = true)
        @test count(endswith(".jl"), readdir(tmp_dir)) == 2
        @test count(endswith(".jl"), readdir(joinpath(tmp_dir, "subdir"))) == 2
        for i = 1:4
            expected = read(replace(python_paths[i], ".py" => ".jl"), String)
            translated = read(replace(tmp_python_paths[i], ".py" => ".jl"), String)
            @test expected == translated
        end
    end
end

@testset "No files to translate" begin
    mktempdir() do tmp_dir
        @test_logs (:warn, "No python files found in `source` path.") translate(tmp_dir)
    end
end

@testset "No base translations" begin
    mktempdir() do tmp_dir
        python_path = joinpath(@__DIR__, "data", "base", "5.py")
        julia_path = joinpath(@__DIR__, "data", "base", "5_no_base_translations.jl")
        tmp_python_path = joinpath(tmp_dir, "5.py")
        tmp_julia_path = joinpath(tmp_dir, "5.jl")
        cp(python_path, tmp_python_path)
        translate(tmp_python_path, include_base_translations = false)
        expected = read(julia_path, String)
        translated = read(tmp_julia_path, String)
        @test expected == translated
    end
end

@testset "Verbose output" begin
    mktempdir() do tmp_dir
        python_file = joinpath(tmp_dir, "file.py")
        write(python_file, "x = 'a'")
        log_file = joinpath(tmp_dir, "logfile.txt")
        open(log_file, "w") do f
            redirect_stdout(f) do
                translate(python_file, verbose = true)
            end
        end
        verbose_output = (read(log_file, String))
        expected_output = """
                          INDENT              ""
                          NAME                "x"
                          SPACE               " "
                          OP                  "="
                          SPACE               " "
                          STRING              "\\"a\\""
                          NEWLINE             ""
                          INDENT              ""
                          ENDMARKER           ""
                          """
        @test verbose_output == expected_output
    end
end
