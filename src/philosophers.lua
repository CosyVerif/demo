#! /usr/bin/env lua

local cli      = require "cliargs"
local connect  = require "cosy.connexion.ev"
local observed = require "cosy.lang.view.observed"

local type = require "cosy.util.type"
local raw  = require "cosy.lang.data" . raw
local map  = require "cosy.lang.iterators" . map
local set  = require "cosy.lang.iterators" . set

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
  print ("Moving existing philosophers.")
  local angle = 360 / (model.number + 1)
  for i=1, model.number do
    think   [i] . position = "40:" .. tostring (angle * i)
    wait    [i] . position = "20:" .. tostring (angle * i)
    eat     [i] . position = "10:" .. tostring (angle * i)
    fork    [i] . position = "30:" .. tostring (angle * i + angle / 2)
    left    [i] . position = "35:" .. tostring (angle * i)
    right   [i] . position = "15:" .. tostring (angle * i)
    release [i] . position = "05:" .. tostring (angle * i)
  end
  -- Add new philosopher:
  model.number = model.number + 1
  print ("Adding philosopher " .. tostring (model.number))
  local i = model.number
  local name = philosophers [i]
  think [i] = {
    type = "place",
    name = name .. " is thinking",
    marking = true,
    position = "40:" .. tostring (angle * i),
  }
  wait [i] = {
    type = "place",
    name = name .. " is waiting",
    marking = false,
    position = "20:" .. tostring (angle * i),
  }
  eat [i] = {
    type = "place",
    name = name .. " is eating",
    marking = false,
    position = "10:" .. tostring (angle * i),
  }
  fork [i] = {
    type = "place",
    name = name .. "'s fork",
    marking = true,
    position = "30:" .. tostring (angle * i + angle / 2),
  }
  left [i] = {
    type = "transition",
    name = name .. " takes his fork",
    position = "35:" .. tostring (angle * i),
  }
  local previous = i == 1 and model.number or i-1
  local next     = i == model.number and 1 or i+1
  if previous ~= i then
    right [previous] . name = philosophers [previous] .. " takes " .. name .. "'s fork"
  end
  right [i] = {
    type = "transition",
    name = name .. " takes " .. philosophers [next] .. "'s fork",
    position = "15:" .. tostring (angle * i),
  }
  release [i] = {
    type = "transition",
    name = name .. " releases forks",
    position = "05:" .. tostring (angle * i),
  }
  arcs [i] = {}
  arcs [i] . think_left = {
    type   = "arc",
    source = think [i],
    target = left [i],
  }
  arcs [i] . fork_left = {
    type   = "arc",
    source = fork [i],
    target = left [i],
  }
  arcs [i] . left_wait = {
    type   = "arc",
    source = left [i],
    target = wait [i],
  }
  arcs [i] . wait_right = {
    type   = "arc",
    source = wait [i],
    target = right [i],
  }
  arcs [i] . right_eat = {
    type   = "arc",
    source = right [i],
    target = eat [i],
  }
  arcs [i] . eat_release = {
    type   = "arc",
    source = eat [i],
    target = release [i],
  }
  arcs [i] . release_think = {
    type   = "arc",
    source = release [i],
    target = think [i],
  }
  arcs [i] . release_fork_1 = {
    type   = "arc",
    source = release [i],
    target = fork [i],
  }
  if previous ~= i then
    if arcs [previous] . fork_right then
      arcs [previous] . fork_right . source = fork [i]
    end
    arcs [i] . fork_right = {
      type   = "arc",
      source = fork [next],
      target = right [i],
    }
    if arcs [previous] . release_fork_2 then
      arcs [previous] . release_fork_2 . target = fork [i]
    end
    arcs [i] . release_fork_2 = {
      type   = "arc",
      source = release [i],
      target = fork [next],
    }
  end
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
    arcs [previous] . fork_right     . source = fork [next]
    arcs [previous] . release_fork_2 . target = fork [next]
  end
  -- Update positions
  model.number = model.number - 1
  local angle = 360 / model.number
  for i=1, model.number - 1 do
    think   [i] . position = "40:"   .. tostring (angle * i)
    wait    [i] . position = "20:"   .. tostring (angle * i)
    eat     [i] . position = "10:"   .. tostring (angle * i)
    fork    [i] . position = "30:"   .. tostring (angle * i + angle / 2)
    left    [i] . position = "35:" .. tostring (angle * i)
    right   [i] . position = "15:" .. tostring (angle * i)
    release [i] . position = "05:" .. tostring (angle * i)
  end
end

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
  for i=1, model.form.generator.quantity.value do
    add ()
    coroutine.yield (1)
  end

  observed [#observed + 1] = function (data, key)
    coroutine.yield ()
    if raw (data) == raw (model.form.generator.generate) and key == "clicked" then
      generate ()
      model.form.generator = nil
      model [cosy.tags.WS] . stop ()
    elseif raw (data) == raw (model.form.generator.quantity) and key == "value" then
      print ("Quantity updated to " .. tostring (model.form.generator.quantity.value))
      local x = tonumber (model.form.generator.quantity.value)
      model [cosy.tags.WS] . execute (function ()
        if math.floor (x) == x and x > 0 then
          if x > model.number then
            for i=model.number+1, x do
              add ()
            end
          elseif x < model.number then
            for i=model.number-1, x, -1 do
              remove ()
            end
          end
          model.form.generator.generate.is_active = true
        end
      end)
    end
  end

end)

model [cosy.tags.WS] . loop ()
