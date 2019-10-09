module(..., package.seeall)
--[[
say is a simple string key/value store for i18n or ay other case where you
want namespaced strings.

Check out [busted](http://www.olivinelabs.com/busted) for
extended examples.

```lua
s = require("say")

s:set_namespace("en")

s:set('money', 'I have %s dollars')
s:set('wow', 'So much money!')

print(s('money', 1000)) -- I have 1000 dollars

s:set_namespace("fr") -- switch to french!
s:set('so_much_money', "Tant d'argent!")

print(s('wow')) -- Tant d'argent!
s:set_namespace("en")  -- switch back to english!
print(s('wow')) -- So much money!
```
--]]

local registry = { }
local current_namespace
local fallback_namespace

local s = {

  _COPYRIGHT   = "Copyright (c) 2012 Olivine Labs, LLC.",
  _DESCRIPTION = "A simple string key/value store for i18n or any other case where you want namespaced strings.",
  _VERSION     = "Say 1.2",

  set_namespace = function(self, namespace)
    current_namespace = namespace
    if not registry[current_namespace] then
      registry[current_namespace] = {}
    end
  end,

  set_fallback = function(self, namespace)
    fallback_namespace = namespace
    if not registry[fallback_namespace] then
      registry[fallback_namespace] = {}
    end
  end,

  set = function(self, key, value)
    registry[current_namespace][key] = value
  end
}

local __meta = {
  __call = function(self, key, vars)
    vars = vars or {}

    local str = registry[current_namespace][key] or registry[fallback_namespace][key]

    if str == nil then
      return nil
    end
    str = tostring(str)
    local strings = {}

    for i,v in ipairs(vars) do
      table.insert(strings, tostring(v))
    end

    return #strings > 0 and str:format(unpack(strings)) or str
  end,

  __index = function(self, key)
    return registry[key]
  end
}

s:set_fallback('en')
s:set_namespace('en')

if _TEST then
  s._registry = registry -- force different name to make sure with _TEST behaves exactly as without _TEST
end

return setmetatable(s, __meta)
