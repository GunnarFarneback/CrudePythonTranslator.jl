    np_eps

Translate `np.finfo(float32).eps` to `eps(Float32)` and
correspondingly for `Float64`.

---
    np_dtype

Translate `x.dtype` to `eltype(x)`.

---
    np_shape

Translate `x.shape` to `size(x)`.

---
    np_size

Translate `x.size` to `length(x)`.

---
    np_ndim

Translate `x.ndim` to `ndims(x)`.

---
    np_types

Translate numpy types to Julia types:

| numpy     | julia   |
|-----------|---------|
|np.bool    | Bool    |
|np.int8    | Int8    |
|np.int16   | Int16   |
|np.int32   | Int32   |
|np.int64   | Int64   |
|np.uint8   | UInt8   |
|np.uint16  | UInt16  |
|np.uint32  | UInt32  |
|np.uint64  | UInt64  |
|np.float32 | Float32 |
|np.float64 | Float64 |

---
    np_astype

Translate `x.astype(T)` to `T.(x)`. Notice that this requires that `T`
is a single token, so numpy types need to already have been converted
to Julia types, e.g. by the `np_types` rule.

---
    np_min_max

Translate `min` and `max` operations. Specifically

| numpy           | julia        |
|-----------------|--------------|
| np.minimum(...) | min.(...)    |
| np.maximum(...) | max.(...)    |
| np.min(...)     | minimum(...) |
| np.max(...)     | maximum(...) |

---
    np_all_any

Translate `np.all(...)` to `all(...)` and correspondingly for `any`.

---
    np_clip

Translate `np.clip(...)` to `clamp.(...)`.

---
    np_random_seed

Translate `np.random.seed(...)` to `Random.seed!(...)`.

---
    np_linspace

Translate `np.linspace(...)` to `range(...)`.

---
    np_isclose

Translate `np.isclose(...)` to `isapprox(...)`.

---
    np_allclose

Translate `np.allclose(...)` to `all(isapprox.(...))`.

---
    numpy

Apply all `np_*` rules in sequence.
