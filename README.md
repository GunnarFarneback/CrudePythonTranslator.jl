# CrudePythonTranslator

A Julia package which can *help* porting Python code into Julia. It
does a syntactical transformation of a Python file at the level of
tokens.

What this package is *not*:

* It is not a transpiler. Most of the time the output will be an
  unrunnable mix of Python and Julia.

* It is not something which allows you to port code without knowing
  both languages.

* It does not help you with the design changes you may need when
  porting the code.

What it does do:

* It reduces the amount of typing you have to do for a literal port.
  In particular it eliminates the most repetitive parts of the typing.

* It automates the error prone step of converting indentation-marked
  blocks into `end`-delimited blocks.

* It retains comments, docstrings, and formatting.

* It supports adding custom translation rules which are appropriate
  for your code base.

## Installation

```
using Pkg
pkg"add CrudePythonTranslator"
```

## Usage

Basic usage is

```
using CrudePythonTranslator
translate(filename)
```

See the `translate` docstring for more options.

## Tutorial

[Tutorial](docs/tutorial.md)

## How it Works

[Design Walkthrough](docs/design.md)

## Custom Translation Rules

A custom translation rule is a function which receives a sequence of
tokens and returns a possibly modified sequence of tokens. To inspect
what tokens you currently have, use the `verbose` keyword argument to
`translate`. For examples of translation rules, see the implementation
of the standard translations in the source code. Enter your custom
translations as additional positional arguments of `translate`, or as
a vector of functions.

Simple translations can often be generated with the `simple_rule`
function, which does not require detailed understanding of the token
representation.

[Rules API](docs/rules_api.md)

## Base Translation Rules

These are used by default. If some of them do not do what you want,
you can disable the default application and add the ones you like.

[Base](docs/rules/base.md)

## Translation Rules Library

These translation rules are available with
```
using CrudePython.Library
```
but you need to add the ones you want to use to the `translate` call.

* [numpy](docs/rules/numpy.md)
* [os.path](docs/rules/os_path.md)
* [pytest](docs/rules/pytest.md)
* [misc](docs/rules/misc.md)

## Contributing

Did you find some missing translation which would be generally
applicable? File an issue or make a PR. Providing a short example of
an input Python file and a translated Julia file, which could be used
as testcase, is particularly appreciated.

## What About Large Language Models?

This tool is too crude to make use of large language models (GPT-4
etc.) If those turn out to be more useful tools, by all means use
them.
