# Rules API

Custom translation rules can be generated with the Rules API:
```
using CrudePythonTranslator: Map, InPlace, IteratedInPlace, Sequence, Rule, simple_rule, auto_token
```

Except for `simple_rule`, these require understanding the [token
representation](design.md).

## Higher Level Functions

### `simple_rule`

The easiest, but most limited way, to write a custom translation rule
is with `simple_rule`. This mostly works as a search and replace, e.g.
```
simple_rule("np.isclose(", "isapprox(")
```
will replace any occurence (which is not part of a string or a
comment) of `np.isclose(` with `isapprox(`.

A more advanced form is
```
simple_rule("np.allclose(", "all(isapprox.(", replace_closing = "))")
```

This will, as before, replace occurences of `np.allclose(` with
`all(isapprox.(`, but also find the matching closing parenthesis and
replace it with two parentheses. E.g.
```
np.allclose(x, y, atol=0.01)
```
is translated to
```
all(isapprox.(x, y, atol=0.01))
```

This can be used with brackets and braces in addition to parentheses.
There is also a corresponding `replace_opening` keyword argument,
which can be used when the pattern starts with a closing delimiter.

Caveat: `simple_rule` uses a custom tokenization of the patterns,
which might plausibly be too simplistic. Should it make a mistake in
tokenization, use `Rule` instead.

### `Rule`

A more flexible construction is `Rule`, and in fact `simple_rule`
internally generates a `Rule`. The previous example could instead have
been written
```
Rule([("NAME", "np"), ("OP", "."), ("NAME", "allclose"), ("OP", "(")],
     [("NAME", "all"), ("OP", "("), ("NAME", "isapprox"), ("OP", "."), ("OP", "(")],
     replace_closing = [("OP", ")"), ("OP", ")")])
```

This requires spelling out all tokens. An intermediate alternative is
to use `auto_token` to guess the token type:

```
Rule(auto_token.(["np", ".", "allclose", "("]),
     auto_token.(["all", "(", "isapprox", ".", "("]),
     replace_closing = auto_token.([")", ")"]))
```

A more powerful functionality of `Rule` is to do pattern matching and
moving tokens around. E.g. to transform
```
foo.dtype
```
into
```
eltype(foo)
```
we need to move `foo` to later in the expression. This can be done by
specifying a regex in the source and an integer in the target:
```
Rule([("NAME", r".*"), ("OP", "."), ("NAME", "dtype")],
     [("NAME", "eltype"), ("OP", "("), ("NAME", 1), ("OP", ")")])
```
Source patterns are numbered consecutively for use in the target.

### `Sequence`

`Sequence(rule1, rule2, ...)` is just a tool to package multiple rules
into one for sequential processing.

## Lower Level Functions

Any function which takes a sequence of tokens (corresponding to a
complete file) as input and returns a processed sequence of tokens as
output can be used with `translate` as a translation rule. This gives
maximum flexibility, given the token representation, but is typically
harder to write than higher level rules. See the source code for
examples.

There are three functions which can assist in building low level
translation functions.

### `Map`

`Map(f)` generates a rule which applies `f` to each token separately.

### `InPlace`

`InPlace(f!)` generates a rule based on a mutating function `f!`.
Basically it just wraps `f!` by also returning the mutated tokens.

### `IteratedInPlace`

`IteratedInPlace(f!)` generates a rule which repeatedly applies the
mutating function `f!` to the tokens, until `f!` returns false, which
it typically should do when no token was updated.
