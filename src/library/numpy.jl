const np_eps = Sequence([Rule([("NAME", "np"), ("OP", "."), ("NAME", "finfo"),
                               ("OP", "("), ("NAME", "np"), ("OP", "."),
                               ("NAME", T), ("OP", ")"), ("OP", "."),
                               ("NAME", "eps")],
                              [("NAME", "eps"), ("OP", "("),
                               ("NAME", uppercasefirst(T)),
                               ("OP", ")")])
                         for T in ("float32", "float64")])

const np_dtype = Rule([("NAME", r".*"), ("OP", "."), ("NAME", "dtype")],
                      [("NAME", "eltype"), ("OP", "("), ("NAME", 1),
                       ("OP", ")")])

const np_shape = Rule([("NAME", r".*"), ("OP", "."), ("NAME", "shape")],
                      [("NAME", "size"), ("OP", "("), ("NAME", 1), ("OP", ")")])

const np_size = Rule([("NAME", r".*"), ("OP", "."), ("NAME", "size")],
                     [("NAME", "length"), ("OP", "("), ("NAME", 1), ("OP", ")")])

const np_ndim = Rule([("NAME", r".*"), ("OP", "."), ("NAME", "ndim")],
                     [("NAME", "ndims"), ("OP", "("), ("NAME", 1), ("OP", ")")])

const np_types = Sequence([simple_rule("np.bool", "Bool"),
                           simple_rule("np.int8", "Int8"),
                           simple_rule("np.int16", "Int16"),
                           simple_rule("np.int32", "Int32"),
                           simple_rule("np.int64", "Int64"),
                           simple_rule("np.uint8", "UInt8"),
                           simple_rule("np.uint16", "UInt16"),
                           simple_rule("np.uint32", "UInt32"),
                           simple_rule("np.uint64", "UInt64"),
                           simple_rule("np.float32", "Float32"),
                           simple_rule("np.float64", "Float64")])

# Note: This won't match until numpy types have been translated into
# julia types.
const np_astype = Rule([("NAME", r".*"), ("OP", "."), ("NAME", "astype"),
                        ("OP", "("), ("NAME", r".*"), ("OP", ")")],
                       [("NAME", 2), ("OP", "."),
                        ("OP", "("), ("NAME", 1), ("OP", ")")])

const np_min_max = Sequence([simple_rule("np.minimum(", "min.("),
                             simple_rule("np.maximum(", "max.("),
                             simple_rule("np.min(", "minimum("),
                             simple_rule("np.max(", "maximum(")])

const np_all_any = Sequence([simple_rule("np.all(", "all("),
                             simple_rule("np.any(", "any(")])
                    
const np_clip = simple_rule("np.clip(", "clamp.(")
const np_random_seed = simple_rule("np.random.seed(", "Random.seed!(")
const np_linspace = simple_rule("np.linspace(", "range(")

const np_isclose = simple_rule("np.isclose(", "isapprox(")
const np_allclose = simple_rule("np.allclose(", "all(isapprox.(",
                                replace_closing = "))")

const numpy = Sequence([np_eps, np_dtype, np_shape, np_size, np_ndim,
                        np_types, np_astype, np_min_max, np_all_any,
                        np_clip, np_random_seed, np_linspace,
                        np_isclose, np_allclose])
