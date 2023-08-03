for name in names(@__MODULE__, all = true)
    startswith(string(name), "_") && continue
    if getfield(@__MODULE__, name) isa CrudePythonTranslator.TranslationRule
        @eval export $name
    end
end
