def foo():
    if True and False:
        return 1
    elif True or False:
        return 2
    assert False, 'Impossible!'
