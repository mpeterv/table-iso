local inspect = require "inspect"
local serpent = require "serpent"
local table_iso = require "table_iso"

local seed = tonumber(arg[1]) or os.time()
print(("Using seed %d"):format(seed))
math.randomseed(seed)

local function random_string()
   return "k" .. tostring(math.random(100))
end

local function random_value(tables, level)
   tables = tables or {}
   level = level or 0

   if level > 0 then
      if level > 4 or math.random() < 0.3 or #tables > 10 then
         return random_string()
      elseif math.random() < 0.5 then
         return tables[math.random(#tables)]
      end
   end

   local t = {}
   table.insert(tables, t)

   for _ = 1, math.random(0, 3) + math.random(0, 3) do
      t[random_value(tables, level + 1)] = random_value(tables, level + 1)
   end

   return t
end

local max_attempts = 1000000

for i = 1, 1000 do
   io.stdout:write(("\rTest #%d"):format(i))
   io.stdout:flush()

   local value = random_value()
   local dumped = serpent.dump(value)
   local _, loaded = assert(serpent.load(dumped))
   local ok, completed = table_iso.check_iso(value, loaded, {max_attempts = max_attempts})

   if not ok then
      print(" - fail")
      print("Original value:")
      print(inspect(value))
      print("Dumped as:")
      print(dumped)
      print("Loaded value:")
      print(inspect(loaded))
      os.exit()
   elseif not completed then
      print((" - unsure if tables match after %d attempts"):format(max_attempts))
   else
      io.stdout:write(" - ok")
   end
end

print()
