    assert_to_test

Convert `assert` statements to `@test` items. Assumes that `assert`
has previously been translated to `@assert`, as done by the base
translations. This rule should obviously only be used when translating
test files.

---
    make_testset

Convert a `test_*` function to an `@testset`.

---
    pytest_raises

Convert a `pytest.raises` to an `@test_throws`.

---
    pytest

Apply all pytest related rules in sequence.
