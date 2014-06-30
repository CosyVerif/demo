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

local self_module = {}

cosy = {
  handlers = {}
}

cosy.form = {
  quantity = {
    type  = "text",
    name  = "# of dining philosophers?",
    value = 2,
    hint  = "a positive integer",
    check = function (x)
      local x = tonumber (x)
      return x ~= nil
         and math.floor (x) == x
         and x > 0
         and x <= #philosophers
    end,
  },
  submit = {
    type = "button",
    name = "Generate!",
    clicked = false,
  }
}

local function generate ()
  local n = tonumber (cosy.form.quantity.value)
  local model = {}
  local angle = 360 / n
  -- places:
  local think   = {}
  local wait    = {}
  local eat     = {}
  local fork    = {}
  for i=1, n do
    local name = philosophers [i]
    think [i] = {
      type = "place",
      name = name .. " thinks",
      marking = true,
      position = "4:" .. tostring (angle * i),
    }
    wait [i] = {
      type = "place",
      name = name .. " waits",
      marking = false,
      position = "2:" .. tostring (angle * i),
    }
    eat [i] = {
      type = "place",
      name = name .. " eats",
      marking = false,
      position = "1:" .. tostring (angle * i),
    }
    fork [i] = {
      type = "place",
      name = "fork of " .. name,
      marking = true,
      position = "3:" .. tostring (angle * i + angle / 2),
    }
  end
  for _, p in ipairs (think) do
    model [#model + 1] = p
  end
  for _, p in ipairs (wait) do
    model [#model + 1] = p
  end
  for _, p in ipairs (eat) do
    model [#model + 1] = p
  end
  for _, p in ipairs (fork) do
    model [#model + 1] = p
  end
  -- transitions:
  local left    = {}
  local right   = {}
  local release = {}
  for i=1, n do
    local name = philosophers [i]
    local neighbor = philosophers [i == 1 and n or i-1]
    left [i] = {
      type = "transition",
      name = name .. " takes his fork",
      position = "3.5:" .. tostring (angle * i),
    }
    right [i] = {
      type = "transition",
      name = name .. " takes " .. neighbor .. " fork",
      position = "1.5:" .. tostring (angle * i),
    }
    release [i] = {
      type = "transition",
      name = name .. " releases forks",
      position = "0.5:" .. tostring (angle * i),
    }
  end
  for _, t in ipairs (left) do
    model [#model + 1] = t
  end
  for _, t in ipairs (right) do
    model [#model + 1] = t
  end
  for _, t in ipairs (release) do
    model [#model + 1] = t
  end
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
  print (model [#model].source)
  cosy.model = model
end

cosy.handlers [self_module] = function (data, key)
  coroutine.yield ()
  if data == cosy.form.quantity and key == "value" then
    generate ()
  elseif data == cosy.form.submit and key == "clicked" then
    generate ()
    cosy.form.quantity = nil
    cosy.form.submit   = nil
  end
end

local serpent = require "serpent"

generate ()
print (serpent.dump (cosy.model, {
  indent   = '  ',
  sortkeys = true,
  comment  = true
}))
