local f = require "dep"

assert (table.pack)
assert (table.unpack)

local key = {}

local data = {
  [key] = "something",
  a = { b = 3 },
}

local v1 = data [key]
local v2 = data.a.b

print (v1)
print (v2)
