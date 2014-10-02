#! /usr/bin/env lua

local global = _ENV or _G
global.ev = true

local Cosy      = require "cosy"
local Data      = require "cosy.data"
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

local function highlight (model)
  local count = 0
  for _, transition in pairs (model) do
    if Helper.is_transition (transition) then
      local all_pre = true
      for _, arc in pairs (model) do
        if  Helper.is_arc (arc)
        and Helper.target (arc) == transition
        and not Helper.source (arc).token () then
          all_pre = false
          break
        end
      end
      if all_pre then
        Helper.highlight (transition)
        count = count + 1
      end
    end
  end
  if count == 0 then
    Cosy.stop ()
  end
end

-- Performs fire:
local function fire (transition)
  local model = transition / 2
  local all_pre = true
  for _, arc in pairs (model) do
    if  Helper.is_arc (arc)
    and Helper.target (arc) == transition
    and not Helper.source (arc).token () then
      all_pre = false
      break
    end
  end
  if all_pre then
    for _, arc in pairs (model) do
      if  Helper.is_arc (arc)
      and Helper.target (arc) == transition
      and Helper.source (arc).token () then
        Helper.source (arc).token = false
      elseif  Helper.is_arc (arc)
      and Helper.source (arc) == transition then
        Helper.target (arc).token = true
      end
    end
  end
  Helper.deselect (transition)
end

function Cosy.main ()
  local model = Helper.resource (resource)
  highlight (model)
  Data.on_write.simulator = function (target)
    if Helper.is_transition (target)
    and Helper.is_selected (target) then
      fire (target)
      highlight (model)
    end
  end
end

Cosy.start ()
