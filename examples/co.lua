local data = {
  [1] = "xyz",
  a = 1,
  b = 2,
}

local function iter (x)
  local f = coroutine.wrap (
    function ()
      for k, v in pairs (x) do
        coroutine.yield (k, v)
      end
    end
  )
  return f
end

for k, v in iter (data) do
  print (tostring (k) .. " => " .. tostring (v))
end

local view_mt = {}
local view = setmetatable ({}, view_mt)

function view_mt:__index (key)
  return data [key]
end

function view_mt:__newindex (key, value)
  data [key] = value
end

function view_mt:__len ()
  return # data
end

function view_mt:__tostring ()
  return table.concat (data, ".")
end

view [2] = "abc"
print (view.a)
print (view)
print (#view)
