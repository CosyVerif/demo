#! /usr/bin/env lua

local cli      = require "cliargs"
local connect  = require "cosy.connexion.ev"

cli:set_name ("model.lua")
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

model [cosy.tags.WS] . execute (function ()

  model.p = {
    type = "place",
    name = "p",
    marking = true,
  }
  model.q = {
    type = "place",
    name = "q",
    marking = true,
  }
  model.r = {
    type = "place",
    name = "r",
    marking = false,
  }
  model.t = {
    type = "transition",
    name = "t",
  }
  model.u = {
    type = "transition",
    name = "u",
  }
  model [1] = {
    type   = "arc",
    source = model.p,
    target = model.t,
  }
  model [2] = {
    type   = "arc",
    source = model.q,
    target = model.t,
  }
  model [3] = {
    type   = "arc",
    source = model.t,
    target = model.r,
  }
  model [4] = {
    type   = "arc",
    source = model.u,
    target = model.p,
  }
  model [5] = {
    type   = "arc",
    source = model.u,
    target = model.q,
  }
  model [6] = {
    type   = "arc",
    source = model.r,
    target = model.u,
  }

  model [cosy.tags.WS] . stop ()

end)

model [cosy.tags.WS] . loop ()
