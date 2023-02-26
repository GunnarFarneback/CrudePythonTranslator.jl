function foo()
    if true && false
        return 1
    elseif true || false
        return 2
    end
    @assert false, "Impossible!"
end
