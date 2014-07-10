#! /usr/bin/env lua

local cli      = require "cliargs"
local connect  = require "cosy.connexion.ev"
local observed = require "cosy.lang.view.observed"

cli:set_name ("philosophers.lua")
cli:add_option (
  "-u, --url=<URL>",
  "editor URL",
  "ws://localhost:8080"
)
cli:add_argument (
  "resource",
  "resource to edit"
)
cli:add_argument (
  "token",
  "user token"
)

local args = cli:parse_args ()
if not args then
  cli:print_help()
  return
end
local url       = args.url
local token     = args.token
local resource  = args.resource

-- Load philosophers list:
local philosophers = {}
for line in io.lines "philosophers.txt" do
  philosophers [#philosophers + 1] = line
end

local function shuffled (tab)
  local n, order, res = #tab, {}, {}
  for i=1,n do order[i] = { rnd = math.random(), idx = i } end
  table.sort (order, function(a,b) return a.rnd < b.rnd end)
  for i=1,n do res[i] = tab[order[i].idx] end
  return res
end

math.randomseed (os.time ())
philosophers = shuffled (philosophers)

local model = connect {
  editor   = url,
  resource = resource,
  token    = token,
}

model [cosy.tags.WS] . execute (function ()
  model.form = {
    generator = {
      name = "Generator",
      type = "form",
      quantity = {
        type  = "text",
        name  = "# of dining philosophers?",
        value = 2,
        hint  = "a positive integer",
      },
      generate = {
        type = "button",
        name = "Generate!",
        clicked   = false,
        is_active = false,
      },
      close = {
        type = "button",
        name = "Close",
        clicked   = false,
        is_active = true,
      },
    },
  }

  model.think   = {}
  model.wait    = {}
  model.eat     = {}
  model.fork    = {}
  model.left    = {}
  model.right   = {}
  model.release = {}
  model.arcs    = {}

  model.number = 0
end)

local function add ()
  local think   = model.think
  local wait    = model.wait
  local eat     = model.eat
  local fork    = model.fork
  local left    = model.left
  local right   = model.right
  local release = model.release
  local arcs    = model.arcs
  -- Update positions:
  local angle = 360 / (model.number + 1)
  for i=1, model.number do
    think   [i] . position = "4:"   .. tostring (angle * i)
    wait    [i] . position = "2:"   .. tostring (angle * i)
    eat     [i] . position = "1:"   .. tostring (angle * i)
    fork    [i] . position = "3:"   .. tostring (angle * i + angle / 2)
    left    [i] . position = "3.5:" .. tostring (angle * i)
    right   [i] . position = "1.5:" .. tostring (angle * i)
    release [i] . position = "0.5:" .. tostring (angle * i)
  end
  -- Add new philosopher:
  model.number = model.number + 1
  local i = model.number
  local name = philosophers [i]
  think [i] = {
    type = "place",
    name = name .. " is thinking",
    marking = true,
    position = "4:" .. tostring (angle * i),
  }
  wait [i] = {
    type = "place",
    name = name .. " is waiting",
    marking = false,
    position = "2:" .. tostring (angle * i),
  }
  eat [i] = {
    type = "place",
    name = name .. " is eating",
    marking = false,
    position = "1:" .. tostring (angle * i),
  }
  fork [i] = {
    type = "place",
    name = name .. "'s fork",
    marking = true,
    position = "3:" .. tostring (angle * i + angle / 2),
  }
  left [i] = {
    type = "transition",
    name = name .. " takes his fork",
    position = "3.5:" .. tostring (angle * i),
  }
  local previous = i == 1 and model.number or i-1
  local next     = i == model.number and 1 or i+1
  if previous ~= i then
    right [previous] . name = philosophers [previous] .. " takes " .. name .. "'s fork"
  end
  right [i] = {
    type = "transition",
    name = name .. " takes " .. philosophers [next] .. "'s fork",
    position = "1.5:" .. tostring (angle * i),
  }
  release [i] = {
    type = "transition",
    name = name .. " releases forks",
    position = "0.5:" .. tostring (angle * i),
  }
end

local function remove ()
  local think   = model.think
  local wait    = model.wait
  local eat     = model.eat
  local fork    = model.fork
  local left    = model.left
  local right   = model.right
  local release = model.release
  local arcs    = model.arcs
  -- Remove philosophers
  local i = model.number
  think   [i] = nil
  wait    [i] = nil
  eat     [i] = nil
  fork    [i] = nil
  left    [i] = nil
  right   [i] = nil
  release [i] = nil
  arcs    [i] = nil
  if i > 1 then
    local previous = i == 1 and model.number or i-1
    local next     = i == model.number and 1 or i+1
    right [previous] . name = philosophers [previous] .. " takes " .. philosophers [next] .. "'s fork"
  end
  -- Update positions
  model.number = model.number - 1
  local angle = 360 / model.number
  for i=1, model.number - 1 do
    think   [i] . position = "4:"   .. tostring (angle * i)
    wait    [i] . position = "2:"   .. tostring (angle * i)
    eat     [i] . position = "1:"   .. tostring (angle * i)
    fork    [i] . position = "3:"   .. tostring (angle * i + angle / 2)
    left    [i] . position = "3.5:" .. tostring (angle * i)
    right   [i] . position = "1.5:" .. tostring (angle * i)
    release [i] . position = "0.5:" .. tostring (angle * i)
  end
end

local function generate ()
  --[[
  -- arcs:
  for i=1, n do
    model [#model + 1] = {
      type   = "arc",
      source = think [i],
      target = left [i],
    }
    model [#model + 1] = {
      type   = "arc",
      source = fork [i],
      target = left [i],
    }
    model [#model + 1] = {
      type   = "arc",
      source = left [i],
      target = wait [i],
    }
    model [#model + 1] = {
      type   = "arc",
      source = wait [i],
      target = right [i],
    }
    model [#model + 1] = {
      type   = "arc",
      source = fork [i == 1 and n or i-1],
      target = right [i],
    }
    model [#model + 1] = {
      type   = "arc",
      source = right [i],
      target = eat [i],
    }
    model [#model + 1] = {
      type   = "arc",
      source = eat [i],
      target = release [i],
    }
    model [#model + 1] = {
      type   = "arc",
      source = release [i],
      target = think [i],
    }
    model [#model +1] = {
      type   = "arc",
      source = release [i],
      target = fork [i],
    }
    model [#model +1] = {
      type   = "arc",
      source = release [i],
      target = fork [i == 1 and n or i-1],
    }
  end
  model = model
  --]]
end

--[[
observed [#observed + 1] = function (data, key)
  coroutine.yield ()
  if data == model.form.generator.generate and key == "clicked" then
    generate ()
    model.form.generator = nil
    model [cosy.tags.WS] . stop ()
  elseif data == model.form.quantity and key == "value" then
    local x = tonumber (x)
    model.form.generator.generate.is_active = x ~= nil
                               and math.floor (x) == x
                               and x > 0
                               and x <= #philosophers
  end
end
--]]

model [cosy.tags.WS] . execute (function ()
  for i=1, model.form.generator.quantity.value do
    add ()
    coroutine.yield (1)
  end
end)

model [cosy.tags.WS] . loop ()
