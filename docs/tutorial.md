# Tutorial

CrudePythonTranslator is a tool to *help* translate Python code to
Julia. It is most useful if you have a moderate to somewhat large
amount of code to port. With a small amount of code the gains compared
to just porting by hand are small and with a huge amount of code you
probably want to find or develop a better tool with some semantic
understanding of the code.

## Python Code Sample

For this tutorial we will, by necessity, only consider a tiny code
example. Assume that we have a file `tutorial.py` containing
```
import numpy as np
# Sample function
def tutorial(x, mode):
    '''
    Sample tutorial function.
    '''
    if mode == 'max':
        # Maximum!
        return np.max(x)
    elif mode == 'min':
        return np.min(x)
```

## Out of the Box Translation

We can run CrudePythonTranslator without any customization like this:

```
using CrudePythonTranslator
translate("tutorial.py")
```

The result is a new file `tutorial.jl`, containing
```
import numpy as np
# Sample function
"""
Sample tutorial function.
"""
function tutorial(x, mode)
    if mode == "max"
        # Maximum!
        return np.max(x)
    elseif mode == "min"
        return np.min(x)
    end
end
```

Crude, eh? This is neither valid Python, nor Julia, but a weird mix
between them, which is what you generally can expect from this
tool. It is assumed that you will finish the translation by hand.

On the positive side we can see that
* `def` has been translated to `function` and `elif` to `elseif`.
* `end` has been inserted where the Python code dedented.
* Single quotes have been converted to double quotes.
* The docstring has been moved from inside the function to above the function.
* All comments and formatting remain unchanged.

All of these are extremely repetitive to do by hand, and in particular
the second item is rather error prone.

## Improved Translation with Library Rules

We can improve on this by applying some additional translation rules
which are shipped with the package.

```
using CrudePythonTranslator.Library: numpy
translate("tutorial.py", numpy, overwrite = true)
```

Note: `translate` will not overwrite an existing Julia file by
default. You might already have done further manual editing!

The result is now
```
import numpy as np
# Sample function
"""
Sample tutorial function.
"""
function tutorial(x, mode)
    if mode == "max"
        # Maximum!
        return maximum(x)
    elseif mode == "min"
        return minimum(x)
    end
end
```

This looks better, only the `import` won't work in Julia. We could
leave this for manual editing but for the sake of this tutorial, let's
take it a step further.

## Improved Translation with a Custom Rule

We can remove the import statement by defining a custom translation rule.

```
remove_import = simple_rule("import numpy as np", "")
translate("tutorial.py", numpy, remove_import, overwrite = true)
```

Finally we have an output that is actually valid Julia:
```

# Sample function
"""
Sample tutorial function.
"""
function tutorial(x, mode)
    if mode == "max"
        # Maximum!
        return maximum(x)
    elseif mode == "min"
        return minimum(x)
    end
end
```

In practice that is only possible for sufficiently small examples.
And even if it can be done for real code bases it's unlikely to be
worth the time to tweak the translation to that point instead of just
finishing up the translations manually.

## Next Steps

To translate a whole code base you can just run
```
translate(python_dir, ...)
```
and all python files within `python_dir`, recursively, will be
translated.

Custom rules can be written with much more flexibility than
`simple_rule` provides. See the [Rules API](rules_api.md)
documentation. They are limited to what can be expressed in terms of
syntactical transformations on a tokenized code representation
though. See [how it works](design.md) if you are curious about the
internal workings.

## Hints

* Add custom rules for frequently occuring patterns in your code
  base. Balance the time of implementing the rules against the time
  needed to translate it manually, taking into account that a rule
  should be somewhat less error-prone than a manual translation.

* It is easier to write rules if the Python code is stylistically
  consistent. It may be useful to run it through your favorite code
  formatter or employ a tool like `flake8` to help make it more
  consistent.

* It helps enormously to have good unit tests for the code you
  port. Consider adding such to the Python code before porting if they
  are missing. Start by porting the tests.

* The PyCall or PythonCall packages are enormously useful for a
  gradual porting.
