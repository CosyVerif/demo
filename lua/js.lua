-- Make window object a global
window = js.global;

http = {}
function http.get (url)
  local xhr = js.new(window.XMLHttpRequest)
  xhr:open("GET", url, false) -- Synchronous
  xhr:send()
  if xhr.status == 0 or xhr.status == 200 then
    return xhr.responseText
  else
    return nil, "HTTP GET " .. xhr.statusText .. ": " .. url
  end
end

-- Iterates from 0 to collection.length-1
local function js_inext (collection, i)
  i = i + 1
  if i >= collection.length then return nil end
  return i, collection [i]
end
function js.ipairs (collection)
  return js_inext, collection, -1
end

local function load_lua_over_http(url)
  local code, err = http.get (url)
  if code then
    return load(code, url)
  else
    return nil, err
  end
end

package.path = ""
package.cpath = ""
table.insert(package.searchers, function (mod_name)
  print ("Loading " .. mod_name)
  if not mod_name:match("/") then
    local full_url = "lua/" .. mod_name:gsub("%.", "/") .. ".lua"
    local func, err = load_lua_over_http(full_url)
    if func ~= nil then return func end
--[[
    local full_url = "lua/" .. mod_name:gsub("%.", "/lua/") .. "/init.lua"
    local func, err2 = load_lua_over_http(full_url)
    if func ~= nil then return func end
--]]
    return "\n    " .. err -- .. "\n    " .. err2
  end
end)
table.insert(package.searchers, function (mod_name)
  if mod_name:match("^https?://") then
    local func, err = load_lua_over_http(mod_name)
    if func == nil then return "\n    " .. err end
    return func
  end
end)
