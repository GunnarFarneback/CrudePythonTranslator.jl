    normalize_string

Convert single quote strings into double quote strings.

---
    no_final_newline

Fix up the token sequence if the file had no final newline.

---
    convert_keywords

Translate `True`, `False`, `def`, `elif`, `or`, `and`, `assert`.

---
    remove_colon

Remove end of line colons.

---
    convert_ops

Translate `**` to `^` and `//` to `÷`.

---
    adjust_end_positions

Correct the placement of `end` with respect to empty lines and comments.

---
    move_docstrings

Move documentation strings from inside the function to above the function.

---
    fix_function_arg_alignment

Adjust the indentation of line-broken function arguments to adapt to
`function` having more characters than `def`.

---
    is_none

Translate `x is None` to `isnothing(x)`.

---
    is_not_none

Translate `x is not None` to `!isnothing(x)`.

---
    not_in

Translate `not in` to `∉`.

---
    not_rule

Translate `not ` to `!`.

---
    none_rule

Translate `none` to `nothing`.

---
    dict_and_set

Translate dictionaries and sets.

---
    base_translations

All base translations. These are run by default.
