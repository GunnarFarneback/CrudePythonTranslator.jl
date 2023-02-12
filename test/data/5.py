def foo():
    if True:
        return 1

    # Won't happen.
    return 0


# Next function.
def bar():
    if True:
        if True:
            return 2

    return 1
