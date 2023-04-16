module CrudePythonTranslator

using Multibreak: @multibreak
using PyCall: pyimport

include("translate.jl")
include("rules.jl")
include("base.jl")

module Library
using ..CrudePythonTranslator
foreach(include, readdir(joinpath(@__DIR__, "library"), join = true))
end

end
