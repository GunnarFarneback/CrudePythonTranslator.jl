def foo():
    if True:
        return 1

    # Won't happen.
    end
    return 0


# Next function.
end
def bar():
    if True:
        if True:
            return 2

        end
    end
    return 1
end
