#! /usr/bin/env lua

local global = _ENV or _G
global.ev = true

local Cosy      = require "cosy"
local Helper    = require "cosy.helper"
local _         = require "cosy.util.string"
local cli       = require "cliargs"
local logging   = require "logging"
logging.console = require "logging.console"
local logger    = logging.console "%level %message\n"
local http      = require "socket.http"
local ltn12     = require "ltn12"
local json      = require "dkjson"

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

function Cosy.main ()
  local url = resource:gsub ("^http://", "http://${username}:${password}@" % {
    username = username,
    password = password,
  })
  local data = json.encode ({
    name        = "P/T net",
    description = "Place/Transition Petri nets",
  })
  logger:info ("Requesting creation of ${resource}." % {
    resource = resource
  })
  local _, code = http.request {
    url = url,
    method = "POST",
    source = ltn12.source.string (data),
    headers = {
      ["content-type"  ] = "application/json",
      ["content-length"] = #data,
    },
  }
  if code ~= 201 then
    logger:error ("Cannot create ${resource}, because ${reason}." % {
      resource = resource,
      reason   = code
    })
    Cosy.stop ()
    return
  end

  logger:info ("Filling ${resource}." % {
    resource = resource
  })
  local model = Helper.resource (resource)

  model.place_type = {}
  model.place_type [tostring (model.place_type)] = true

  model.transition_type = {}
  model.transition_type [tostring (model.transition_type)] = true

  model.arc_type = {}
  model.arc_type [tostring (model.arc_type)] = true

  Cosy.stop ()
end

Cosy.start ()
