package = "table-iso"
version = "scm-1"
source = {
   url = "git+https://github.com/mpeterv/table-iso.git"
}
description = {
   summary = "Lua table structural equivalence (isomorphism) checker",
   detailed = [[
table-iso deeply compares two tables, supporting table keys and ensuring
that all table values are referenced in the same way in both tables.]],
   homepage = "https://github.com/mpeterv/table-iso",
   license = "MIT"
}
dependencies = {}
build = {
   type = "builtin",
   modules = {
      table_iso = "src/table_iso.lua"
   }
}
