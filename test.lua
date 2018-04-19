local table_iso = require "table_iso"

local t1 = {}

t1[t1]=t1
t1.x = {[t1] = {1, 2, 3}}

local t2 = {}
local t3 = {}

t2[t3]=t2
t3[t2]=t3
t2.x = {[t3] = {1, 2, 3}}
t3.x = {[t2] = {1, 2, 3}}

assert(table_iso.check_iso(t1, t2) == false)
assert(table_iso.check_iso(t2, t3) == true)

local t4 = {}
t4[{}] = 1
t4["1"] = {}

local t5 = {}
local t6 = {}
t5[t6] = 1
t5["1"] = t6

assert(table_iso.check_iso(t4, t5) == false)

local t7 = {{}, {}}
local empty = {}
local t8 = {empty, empty}

assert(table_iso.check_iso(t7, t8) == false)


local t9 = {[{}] = 1}
local t10 = {[{}] = 1}
assert(table_iso.check_iso(t9, t10))
