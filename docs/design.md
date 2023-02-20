# Design Walkthrough

The starting point of any translation is Python code. We will use this
example to show the internals of the translation process:

```python
def f(a, b):
    if a == b:
        return 1
    else:
        # Not equal.
        return '2'
```

The general approach of the translation is to split the input code
into tokens and then manipulate the sequence of tokens to gradually
make the code look more like Julia and less like Python.

The first step is to call out to Python's `tokenize` standard library,
which by definition is the authority on tokenizing Python code. This
gives us a sequence of tuples starting with
```
[(1, "def", (1, 0), (1, 3), "def f(a, b):\n"),
 (1, "f", (1, 4), (1, 5), "def f(a, b):\n"),
 (54, "(", (1, 5), (1, 6), "def f(a, b):\n")
 ...
```

This representation is better viewed by running `tokenize` as a
script, `python -m tokenize filename`:
```
1,0-1,3:            NAME           'def'
1,4-1,5:            NAME           'f'
1,5-1,6:            OP             '('
1,6-1,7:            NAME           'a'
1,7-1,8:            OP             ','
1,9-1,10:           NAME           'b'
1,10-1,11:          OP             ')'
1,11-1,12:          OP             ':'
1,12-1,13:          NEWLINE        '\n'
2,0-2,4:            INDENT         '    '
2,4-2,6:            NAME           'if'
2,7-2,8:            NAME           'a'
2,9-2,11:           OP             '=='
2,12-2,13:          NAME           'b'
2,13-2,14:          OP             ':'
2,14-2,15:          NEWLINE        '\n'
3,0-3,8:            INDENT         '        '
3,8-3,14:           NAME           'return'
3,15-3,16:          NUMBER         '1'
3,16-3,17:          NEWLINE        '\n'
4,4-4,4:            DEDENT         ''
4,4-4,8:            NAME           'else'
4,8-4,9:            OP             ':'
4,9-4,10:           NEWLINE        '\n'
5,8-5,23:           COMMENT        '# Special case.'
5,23-5,24:          NL             '\n'
6,0-6,8:            INDENT         '        '
6,8-6,14:           NAME           'return'
6,15-6,18:          STRING         "'2'"
6,18-6,19:          NEWLINE        '\n'
7,0-7,0:            DEDENT         ''
7,0-7,0:            DEDENT         ''
7,0-7,0:            ENDMARKER      ''
```

The first column is the range of characters spanning the token. The
second column translates the numeric token codes to readable strings
and the third column shows the source characters represented by the
token.

This is a very good starting point but not really great to keep
working with. Specifically:

* `INDENT` and `DEDENT` are central to Python syntax but for Julia we
  need `end` in place of `DEDENT`. `INDENT` tokens are only inserted
  where the indentation increases.

* Whitespace is mostly not represented by the tokens. This is
  reasonable for typical use cases of tokenized code but we want to
  retain formatting wherever possible, so need to keep track of the
  spaces.

* It's not straightforward to turn the tokens back into formatted
  source code. The `tokenize` library can do that for us with the
  original tokenization but will not be happy when we start to
  transform the tokens into Julia.

The second step of the translation is to preprocess the Python tokens
into a better token representation for our purpose. This gives a
result starting with

```
[("INDENT", ""),
 ("NAME", "def"),
 ("SPACE", " "),
 ("NAME", "f"),
 ...
```

The best way to view this representation is to run
`translate(filename, verbose=true, include_base_translations=false)`:

```
INDENT              ""
NAME                "def"
SPACE               " "
NAME                "f"
OP                  "("
NAME                "a"
OP                  ","
SPACE               " "
NAME                "b"
OP                  ")"
OP                  ":"
NEWLINE             "\n"
INDENT              "    "
NAME                "if"
SPACE               " "
NAME                "a"
SPACE               " "
OP                  "=="
SPACE               " "
NAME                "b"
OP                  ":"
NEWLINE             "\n"
INDENT              "        "
NAME                "return"
SPACE               " "
NUMBER              "1"
NEWLINE             "\n"
INDENT              "    "
NAME                "else"
OP                  ":"
NEWLINE             "\n"
INDENT              "    "
SPACE               "    "
COMMENT             "# Not equal."
NL                  "\n"
INDENT              "        "
NAME                "return"
SPACE               " "
STRING              "'2'"
NEWLINE             "\n"
INDENT              "    "
END                 "end"
NEWLINE             "\n"
INDENT              ""
END                 "end"
NEWLINE             "\n"
INDENT              ""
ENDMARKER           ""
```

Now each token is just a tuple of two strings, where the first is the
token type in clear text and the second is the source code characters
comprising the token. Additionally this differs from the Python tokens
in the following ways:

* `DEDENT` tokens are replaced by `END` tokens.

* Every line (except inside multiline strings and comments) starts
  with an `INDENT` token, possibly corresponding to an empty string.

* Other whitespace than indentation and newlines has been inserted as
  `SPACE` tokens.

* Most importantly, converting the tokens back to source code is now
  as simple as concatenating all the strings in the second column!

Doing the latter at this point renders as

```
def f(a, b):
    if a == b:
        return 1
    else:
        # Not equal.
        return '2'
    end
end
```

Obviously this is neither valid Python code, nor valid Julia code,
which is to be expected also for the final translation result, except
in sufficiently simple cases.

From here everything will be a question of transforming the token
sequence small step by small step, e.g. replacing `def` by `function`
and removing the colons at the end of lines.

Token transformations will be the subject of a future documentation
page but for now let us take note of some properties:

* Comments are their own tokens and nothing inside the comments will
  confuse the translation. (As a corollary, code within a comment will
  not be translated.)

* Likewise strings are their own tokens and their contents will not be
  mixed up with the rest of code.

* The token representation is powerful enough to make many useful
  transformations but it does not constitute a syntax tree, so it is
  difficult to do any really deep analysis of the code.

* The "SPACE" tokens sometimes get in the way but the value they
  provide in allowing a trivial rendering of the code is a worthwhile
  tradeoff.

* Newlines are represented by either `NEWLINE` or `NL` tokens. These
  have different syntactical meaning, which is best observed from code
  examples. (Unless you can find `tokenize` documentation explaining
  the distinction.)
