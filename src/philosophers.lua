#! /usr/bin/env lua

local global = _ENV or _G
global.ev = true

local Cosy      = require "cosy"
local Data      = require "cosy.data"
local Tag       = require "cosy.tag"
local Helper    = require "cosy.helper"
local _         = require "cosy.util.string"
local cli       = require "cliargs"
local logging   = require "logging"
logging.console = require "logging.console"
local logger    = logging.console "%level %message\n"

cli:set_name ("pt.lua")
cli:add_argument(
  "resource",
  "resource to edit"
)
cli:add_option (
  "--username=<string>",
  "username"
)
cli:add_option (
  "--password=<string>",
  "password"
)
cli:add_option (
  "--editor=<URL>",
  "editor URL",
  "ws://edit.cosyverif.io:8080"
)
cli:add_flag (
  "-v, --verbose",
  "enable verbose mode"
)
local args = cli:parse_args ()
if not args then
  cli:print_help()
  return
end

local editor       = args.editor
local resource     = args.resource
local username     = args.username
local password     = args.password
local verbose_mode = args.verbose

if verbose_mode then
  logger:setLevel (logging.DEBUG)
else
  logger:setLevel (logging.INFO)
end

Helper.configure_editor (editor)
Helper.configure_server ("", {
  username = username,
  password = password,
})

local function shuffled (tab)
  local n, order, res = #tab, {}, {}
  for i=1,n do order[i] = { rnd = math.random(), idx = i } end
  table.sort (order, function(a,b) return a.rnd < b.rnd end)
  for i=1,n do res[i] = tab[order[i].idx] end
  return res
end
math.randomseed (os.time ())

logger:info "Loading philosophers list..."
local philosophers = {}
for line in io.lines "philosophers.txt" do
  philosophers [#philosophers + 1] = line
end
philosophers = shuffled (philosophers)

local function add (model)
  model.number = model.number () + 1
  local number = model.number ()
  logger:info ("Adding philosopher ${number}." % {
    number = number
  })
  local name      = philosophers [number]
  local next_name = philosophers [1]
  -- Places:
  local think = Helper.instantiate (model, model.think_type, {
    name    = name .. " is thinking",
    marking = true,
    i       = number,
  })
  local wait = Helper.instantiate (model, model.wait_type, {
    name    = name .. " is waiting",
    marking = false,
    i       = number,
  })
  local eat = Helper.instantiate (model, model.eat_type, {
    name    = name .. " is eating",
    marking = false,
    i       = number,
  })
  local fork = Helper.instantiate (model, model.fork_type, {
    name    = name .. "'s fork",
    marking = true,
    i       = number,
  })
  -- Transitions:
  local left = Helper.instantiate (model, model.left_type, {
    name = name .. " takes his fork",
    i    = number,
  })
  local right = Helper.instantiate (model, model.right_type, {
    name = name .. " takes " .. next_name .. "'s fork",
    i    = number,
  })
  local release = Helper.instantiate (model, model.release_type, {
    name = name .. " releases forks",
    i    = number,
  })
  -- Arcs:
  --[[
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
  --]]
end

function Cosy.main ()
  logger:info ("Connecting to ${resource}..." % {
    resource = resource
  })
  local pt    = Helper.resource "http://rest.cosyverif.io/users/alban/formalisms/pt"
  local model = Helper.resource (resource)
  model [Tag.PARENT] = pt
  model.number = 0

  -- Create types:
  model.think_type   = model.place_type * {
    position = function (self)
      local i = self.i ()
      local n = (self / 2).number ()
      local angle = 360 / (n+1)
      return "40:${angle}" % { angle = angle * i }
    end
  }
  model.wait_type    = model.place_type * {
    position = function (self)
      local i = self.i ()
      local n = (self / 2).number ()
      local angle = 360 / (n+1)
      return "20:${angle}" % { angle = angle * i }
    end
  }
  model.eat_type     = model.place_type * {
    position = function (self)
      local i = self.i ()
      local n = (self / 2).number ()
      local angle = 360 / (n+1)
      return "10:${angle}" % { angle = angle * i }
    end
  }
  model.fork_type    = model.place_type * {
    position = function (self)
      local i = self.i ()
      local n = (self / 2).number ()
      local angle = 360 / (n+1)
      return "30:${angle}" % { angle = angle * i + angle / 2}
    end
  }
  model.left_type    = model.transition_type * {
    position = function (self)
      local i = self.i ()
      local n = (self / 2).number ()
      local angle = 360 / (n+1)
      return "35:${angle}" % { angle = angle * i }
    end
  }
  model.right_type   = model.transition_type * {
    position = function (self)
      local i = self.i ()
      local n = (self / 2).number ()
      local angle = 360 / (n+1)
      return "15:${angle}" % { angle = angle * i }
    end
  }
  model.release_type = model.transition_type * {
    position = function (self)
      local i = self.i ()
      local n = (self / 2).number ()
      local angle = 360 / (n+1)
      return "05:${angle}" % { angle = angle * i }
    end
  }
  add (model)
  add (model)

  model.insert = Helper.instantiate (model, model.transition_type, {
    name = "+1"
  })
  Data.on_write.philosophers = function (target)
    if target == model.insert and Helper.is_selected (model.insert) then
      Helper.deselect (model.insert)
      add (model)
    end
  end

  Cosy.stop ()
end

Cosy.start ()
