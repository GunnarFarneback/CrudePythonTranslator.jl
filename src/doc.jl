function add_docs(m, filename)
    for s in split(replace(readchomp(filename), "\r" => ""), "---\n")
        rule_name, doc = strip.(split(s, "\n\n", keepempty = false, limit = 2))
        rule = getfield(m, Symbol(rule_name))
        rule.doc = doc
    end
end

rules_doc_dir = joinpath(@__DIR__, "../docs/rules")
for filename in readdir(rules_doc_dir, join = true)
    endswith(filename, ".md") || continue
    if endswith(filename, "base.md")
        add_docs(CrudePythonTranslator, filename)
    else
        add_docs(CrudePythonTranslator.Library, filename)
    end
end
