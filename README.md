# table-iso

Standard deep comparison algorithms don't recurse into table keys or consider structural equivalence:


```lua
local luassert = require "luassert"
local table_iso = require "table_iso"

local a = {{}, {}}
local empty = {}
local b = {empty, empty}

luassert.same(a, b) -- Even though `b` reuses tables and `a` doesn't.
assert(not table_iso.check_iso(t7, t8))

local c = {[{}] = 1}
local d = {[{}] = 1}
luassert.not_same(t9, t10) -- Structurally same table keys are considered distinct.
assert(table_iso.check_iso(t9, t10))
```

Two tables `root1 and `root2` are considered structurally equivalent (isomorphic) iff there is a bijection `F`
between sets of tables found within the two tables with the following property:
let `F'` be `F` for tables and identity for other values; for each table `t` found within the first table for
each key-value pair `[k] = v` in `t` `F(t)` must have key-value pair `[F'(k)] = F'(v)` and have no other
key-value pairs. Additionally, `F(root1)` must be `root2`.

## Status

table-iso currently is just an experiment for testing [serpent](https://github.com/pkulchenko/serpent): for any
randomly generated recursive table `t` and its copy `t2` obtained by dumping and loading `t` again calling
`table_iso.check_iso(t, t2)` should return `true`.

table-iso may be helpful for testing other serializers or have other use cases; for now it needs its own tests,
documentation, and some refactoring and optimization.
