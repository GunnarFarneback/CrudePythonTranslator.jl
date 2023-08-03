const append_rule = Rule([("NAME", r".*"), ("OP", "."), ("NAME", "append"),
                          ("OP", "(")],
                         [("NAME", "push!"), ("OP", "("), ("NAME", 1),
                          ("OP", ","), ("SPACE", " ")])

const bool_rule = simple_rule("bool", "Bool")

# Change `for x, y in` to `for (x, y) in`.
const for_tuple = Rule([("NAME", "for"), ("SPACE", " "), ("NAME", r".*"),
                        ("OP", ","), ("SPACE", " "), ("NAME", r".*"),
                        ("SPACE", " "), ("NAME", "in")],
                       [("NAME", "for"), ("SPACE", " "), ("OP", "("),
                        ("NAME", 1), ("OP", ","), ("SPACE", " "),
                        ("NAME", 2), ("OP", ")"), ("SPACE", " "),
                        ("NAME", "in")])

const len_rule = simple_rule("len(", "length(")
const print_rule = simple_rule("print(", "println(")
const str_rule = simple_rule("str(", "string(")

const misc_rules = Sequence([append_rule, bool_rule, for_tuple, len_rule,
                             print_rule, str_rule])
