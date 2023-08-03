const os_path_dirname = simple_rule("os.path.dirname", "dirname")
const os_path_join = simple_rule("os.path.join", "joinpath")
const os_path_realpath = simple_rule("os.path.realpath", "realpath")
const os_path = Sequence([os_path_dirname, os_path_join, os_path_realpath])
