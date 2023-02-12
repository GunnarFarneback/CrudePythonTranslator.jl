function foo(x, y)
    if x ∉ y
        return 0
    elseif y  ∉    x
        return 1
    end
end


function bar(x, y)
    if !x
        return 1
    elseif !y
        return 2
    end
end
