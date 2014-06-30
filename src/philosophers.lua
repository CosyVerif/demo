-- Generator for the Dining Philosophers model

-- Load philosophers list:
local philosophers = {}
for line in io.lines "philosophers.txt" do
  philosophers [#philosophers + 1] = line
end

function shuffled (tab)
  local n, order, res = #tab, {}, {}
  for i=1,n do order[i] = { rnd = math.random(), idx = i } end
  table.sort (order, function(a,b) return a.rnd < b.rnd end)
  for i=1,n do res[i] = tab[order[i].idx] end
  return res
end

math.randomseed (os.time ())
philosophers = shuffled (philosophers)

cosy = {
  handlers = {}
}

cosy.form = {
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
  }
}

local current_number = 0

cosy.model = {}
cosy.model.think   = {}
cosy.model.wait    = {}
cosy.model.eat     = {}
cosy.model.fork    = {}
cosy.model.left    = {}
cosy.model.right   = {}
cosy.model.release = {}
cosy.model.arcs    = {}

local function add ()
  local think   = cosy.model.think
  local wait    = cosy.model.wait
  local eat     = cosy.model.eat
  local fork    = cosy.model.fork
  local left    = cosy.model.left
  local right   = cosy.model.right
  local release = cosy.model.release
  local arcs    = cosy.model.arcs
  -- Update positions:
  local angle = 360 / (current_number + 1)
  for i=1, current_number do
    think   [i] . position = "4:"   .. tostring (angle * i)
    wait    [i] . position = "2:"   .. tostring (angle * i)
    eat     [i] . position = "1:"   .. tostring (angle * i)
    fork    [i] . position = "3:"   .. tostring (angle * i + angle / 2)
    left    [i] . position = "3.5:" .. tostring (angle * i)
    right   [i] . position = "1.5:" .. tostring (angle * i)
    release [i] . position = "0.5:" .. tostring (angle * i)
  end
  -- Add new philosopher:
  current_number = current_number + 1
  local i = current_number
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
  local previous = i == 1 and current_number or i-1
  local next     = i == current_number and 1 or i+1
--  print ("current = " .. current_number .. ", i = " .. tostring (i) .. ", previous = " .. tostring (previous) .. ", next = " .. tostring (next))
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
  local think   = cosy.model.think
  local wait    = cosy.model.wait
  local eat     = cosy.model.eat
  local fork    = cosy.model.fork
  local left    = cosy.model.left
  local right   = cosy.model.right
  local release = cosy.model.release
  local arcs    = cosy.model.arcs
  -- Remove philosophers
  local i = current_number
  think   [i] = nil
  wait    [i] = nil
  eat     [i] = nil
  fork    [i] = nil
  left    [i] = nil
  right   [i] = nil
  release [i] = nil
  arcs    [i] = nil
  if i > 1 then
    local previous = i == 1 and current_number or i-1
    local next     = i == current_number and 1 or i+1
    right [previous] . name = philosophers [previous] .. " takes " .. philosophers [next] .. "'s fork"
  end
  -- Update positions
  current_number = current_number - 1
  local angle = 360 / current_number
  for i=1, current_number - 1 do
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
  local n = tonumber (cosy.form.quantity.value)
  if not n then
    return
  end
  if n < 0 then
    local delay = 1 / n
    for i=-1, n, -1 do
      remove ()
    end
  elseif n > 0 then
    local delay = 1 / n
    for i=1, n do
      add ()
    end
  end

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
  cosy.model = model
  --]]
end

cosy.handlers.philosophers = function (data, key)
  coroutine.yield ()
  if data == cosy.form.generate and key == "clicked" then
    generate ()
    cosy.form.quantity = nil
    cosy.form.submit   = nil
    os.exit (0)
  elseif data == cosy.form.quantity and key == "value" then
    local x = tonumber (x)
    cosy.form.generate.is_active = x ~= nil
                               and math.floor (x) == x
                               and x > 0
                               and x <= #philosophers
  end
end

--[[
local serpent = require "serpent"

generate ()
print (serpent.dump (cosy.model, {
  indent   = '  ',
  sortkeys = true,
  comment  = true
}))
--]]

-- Use copas to do an infinite loop?
local serpent = require "serpent"

for i=1, cosy.form.quantity.value do
  add ()
  print (serpent.dump (cosy, {
    indent   = '  ',
    sortkeys = true,
    comment  = true
  }))
end

while true do
  cosy.form.quantity.value = io.read ("*n")
  generate ()
  print (serpent.dump (cosy, {
    indent   = '  ',
    sortkeys = true,
    comment  = true
  }))
end
