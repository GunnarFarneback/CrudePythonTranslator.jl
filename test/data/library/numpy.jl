eps(Float32)
eps(Float64)

eltype(x)
size(x)
length(x)
ndims(x)

Bool
Int8
Int16
Int32
Int64
UInt8
UInt16
UInt32
UInt64
Float32
Float64

Int32.(x)
# Nonsensical half-Python to unit test the np_astype translation rule.
Int32.(x)

min.(x)
max.(x)
minimum(x)
maximum(x)

all(x)
any(x)

clamp.(x, 0, 1)
Random.seed!(13)
range(0, 10, 100)

isapprox(x, y, atol=0.1)
all(isapprox.(x, y, rtol=0.1))
