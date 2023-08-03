    append_rule

Translate `x.append(...)` to `push!(x, ...)`.

---
    bool_rule

Translate `bool` to `Bool`.

---
    for_tuple

Translate `for x, y in ...` to `for (x, y) in ...`.

---
    len_rule

Transform `len(...)` to `length(...)`.

---
    print_rule

Transform `print(...)` to `println(...)`.

---
    str_rule

Transform `str(...)` to `string(...)`.

---
    misc_rules

Apply all misc rules in sequence.
