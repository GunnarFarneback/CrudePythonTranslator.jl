np.finfo(np.float32).eps
np.finfo(np.float64).eps

x.dtype
x.shape
x.size
x.ndim

np.bool
np.int8
np.int16
np.int32
np.int64
np.uint8
np.uint16
np.uint32
np.uint64
np.float32
np.float64

x.astype(np.int32)
# Nonsensical half-Python to unit test the np_astype translation rule.
x.astype(Int32)

np.minimum(x)
np.maximum(x)
np.min(x)
np.max(x)

np.all(x)
np.any(x)

np.clip(x, 0, 1)
np.random.seed(13)
np.linspace(0, 10, 100)

np.isclose(x, y, atol=0.1)
np.allclose(x, y, rtol=0.1)
