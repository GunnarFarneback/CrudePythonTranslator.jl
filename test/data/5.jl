function foo()
    if true
        return 1
    end

    # Won't happen.
    return 0
end


# Next function.
function bar()
    if true
        if true
            return 2
        end
    end

    return 1
end
