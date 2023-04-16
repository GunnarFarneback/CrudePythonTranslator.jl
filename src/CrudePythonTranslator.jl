module CrudePythonTranslator

using Multibreak: @multibreak
using PyCall: pyimport
import Markdown

include("translate.jl")
include("rules.jl")
include("base.jl")

module Library
using ..CrudePythonTranslator
foreach(include, readdir(joinpath(@__DIR__, "library"), join = true))
include("export_rules.jl")
end

include("doc.jl")

end
