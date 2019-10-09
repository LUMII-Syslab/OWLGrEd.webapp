module(..., package.seeall)

---------------------------------------------
-- Return indentation string for passed level
---------------------------------------------
local function tabs(i)
  return string.rep(" ",i).." "   -- Dots space by a space
end

-----------------------------------------------------------
-- Return string representation of parameter's value & type
-----------------------------------------------------------
local function toStrType(t)
  local function fttu2hex(t) -- Grab hex value from tostring() output
    local str = tostring(t);
    if str == nil then
      return "tostring() failure! \n"
    else
      local str2 = string.match(str,"[ :][ (](%x+)")
      if str2 == nil then
        return "string.match() failure: "..str.."\n"
      else
        return "0x"..str2
      end
    end
  end
  -- Stringify a value of a given type using a table of functions keyed
  -- by the name of the type (Lua's version of C's switch() statement).
  local stringify = {
    -- Keys are all possible strings that type() may return,
    -- per http://www.lua.org/manual/5.1/manual.html#pdf-type.
    ["nil"]       = function(v) return "nil"        end,
    ["string"]    = function(v) return v            end,
    ["number"]    = function(v) return v            end,
    ["boolean"]   = function(v) return tostring(v)  end,
    ["function"]  = function(v) return fttu2hex(v)  end,
    ["table"]     = function(v) return fttu2hex(v)  end,
    ["thread"]    = function(v) return fttu2hex(v)  end,
    ["userdata"]  = function(v) return fttu2hex(v)  end
  }
  return stringify[type(t)](t)
end

--------------------------------
-- Pretty-print the passed table
--------------------------------
local function do_dumptable(t, indent, seen)
  local dump = ""
  -- "seen" is an initially empty table used to track all tables
  -- that have been dumped so far.  No table is dumped twice.
  -- This also keeps the code from following self-referential loops,
  -- the need for which was found when first dumping "_G".
  if ("table" == type(t)) then	-- Dump passed table
    seen[t] = 1
    for f,v in pairs(t) do
      if ("table" == type(v)) and (seen[v] == nil) then  -- Recurse
        dump = dump .. tabs(indent)..toStrType(f) .. " = " .. "{\n"
        dump = dump .. do_dumptable(v, indent+1, seen)
        dump = dump .. tabs(indent).."},\n"
      else
        dump = dump .. tabs(indent)..toStrType(f).." = '"..toStrType(v) .. "',\n"
      end
    end
  else
    dump = dump .. tabs(indent).."Not a table!\t" .. tostring(t) .. "\n"
  end
  
  return dump
end

--------------------------------
-- Wrapper to handle persistence
--------------------------------
function dumptable(t)   -- Only global declaration in the package
  -- This wrapper exists only to set the environment for the first run:
  -- The second param is the indentation level.
  -- The third param is the list of tables dumped during this call.
  -- Getting this list allocated and freed was a pain, and this
  -- wrapper was the best solution I came up with...
  return "{\n" .. do_dumptable(t, 0, {}) .. "}"
end