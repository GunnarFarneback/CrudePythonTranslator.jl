assert x == y
assert x == y, "x should equal y"

def test_foo():
    assert 1 == 1

with pytest.raises(AssertionError):
    foo()
