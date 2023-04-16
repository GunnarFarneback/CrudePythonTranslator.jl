function find_python_data_files(data_path)
    return filter(endswith(".py"),
                  readdir(joinpath(@__DIR__, "data", data_path), join = true))
end

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
        return success
    end
end
