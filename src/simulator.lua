#! /usr/bin/env lua

local cli      = require "cliargs"
local connect  = require "cosy.connexion.ev"
local observed = require "cosy.lang.view.observed"

local type = require "cosy.util.type"
local raw  = require "cosy.lang.data" . raw
local map  = require "cosy.lang.iterators" . map
local set  = require "cosy.lang.iterators" . set

cli:set_name ("simulator.lua")
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

local model = connect {
  editor   = url,
  resource = resource,
  token    = token,
}

local function elements (e)
  local function f (e, seen)
    local result = {}
    seen = seen or {}
    if seen [e] then
      return result
    end
    seen [e] = true
    for k, x in map (e) do
      if type (k) . tag and not k.persistent then
        -- nothing
      elseif type (x) . table then
        if x.type then
          result [raw (x)] = true
        end
        for y in set (f (x, seen)) do
          result [y] = true
        end
      end
    end
    return result
  end

  local result = {}
  for x in set (f (e)) do
    result [observed (x)] = true
  end
  return result
end

-- Highlights fireable transitions:
local function highlight ()
  local number = 0
  local nodes = elements (model)
  for transition in set (nodes) do
    if transition.type == "transition" then
      local fireable = true
      for arc in set (nodes) do
        if arc.type == "arc" and
           raw (arc.target) == raw (transition) and
           not arc.source.marking then
          fireable = false
        end
      end
      if fireable ~= transition.highlighted then
        transition.highlighted = fireable
      end
      print ("Transition " .. transition.name .. " can be fired? " .. tostring (transition.highlighted))
      if fireable then
        number = number + 1
      end
    end
  end
  if number == 0 then
    model.form.simulator.message = "Congratulations, you have reached a deadlock!"
  end
end

local function clean ()
  local nodes = elements (model)
  for transition in set (nodes) do
    transition.highlighted = false
  end
end

-- Performs fire:
local function fire (transition)
  print ("Firing transition " .. transition.name)
  local o = observed [#observed]
  observed [#observed] = nil
  local nodes = elements (model)
  for arc in set (nodes) do
    if arc.type == "arc" and
       raw (arc.target) == raw (transition) then
       arc.source.marking = false
     elseif arc.type == "arc" and
       raw (arc.source) == raw (transition) then
       arc.target.marking = true
    end
  end
  for place in set (nodes) do
    if place.type == "place" then
      print ("Place: " .. place.name .. " = " .. tostring (place.marking))
    end
  end
  observed [#observed] = o
  transition.selected = false
end


model [cosy.tags.WS] . execute (function ()
  model.form = {
    simulator = {
      name = "Simulator",
      type = "form",
      message = {
        type  = "text",
        name  = "Message",
        value = "",
        hint  = "",
      },
      close = {
        type = "button",
        name = "Close",
        clicked   = false,
        is_active = true,
      },
    },
  }
  highlight ()
  observed [#observed + 1] = function (data, key)
    coroutine.yield ()
    if raw (data) == raw (model.form.simulator.close) and
       key == "clicked" then
      clean ()
      model.form.simulator = nil
      model [cosy.tags.WS] . stop ()
    elseif key == "message" then
    elseif data.type == "transition" and
      key == "highlighted" then
    elseif data.type == "transition" and
      key == "selected" and
      data [key] then
      model [cosy.tags.WS] . execute (function ()
        fire (data)
        highlight ()
      end)
    else
      model [cosy.tags.WS] . execute (function ()
        highlight ()
      end)
    end
  end
end)

model [cosy.tags.WS] . loop ()
