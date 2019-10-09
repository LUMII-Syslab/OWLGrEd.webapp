module(..., package.seeall)
-- require "prettyprint"
-- dumptable = prettyprint.dumptable
m = require("lpeg")

local function set_capture_name(pat, name)
  return m.Ct(m.Cg(pat, name))
end

local function collect_captures(pat)
  return m.Cf(pat, function(ci, cj)
        for k,v in pairs(cj) do 
          ci[k] = v 
        end
      return ci
    end)
end

local function function_parser(pat, function_name)
  return collect_captures(m.Ct(m.Cg(m.Cc(function_name), "function_name")) * set_capture_name(pat, "arg"))
end

-- Grammar
local Union = m.V"Union"
local Intersection = m.V"Intersection"
local AttrPath = m.V"AttrPath"
local Result = m.V"Result"


-- Lexical Elements
local space = m.S(" \t")^0

--paplasinats, lai stradatu ar TDA 2 (jo tur klasu vardos var but ::)
local start_sym = m.R("az", "AZ") + m.S"_" + m.P"::"
local sym = start_sym + m.R"09" + m.S"#" + m.P"::"
local word = m.C(start_sym * sym^0) * space

local type_name = set_capture_name(m.P(".")^-1 * word, "type_name")
local any_type = set_capture_name("*" * m.Cc(true) * space, "any_type")
local type_filter = function_parser(type_name + any_type, "filter_by_type")

local value_without_quotes = m.C((m.P(1) - m.S"]),")^0) * space -- m.P(1) corrected by SK
local value_with_quotes = "'" * m.C((m.P(1) - m.P"'")^0) * "'" * space
local value = value_with_quotes + value_without_quotes

local attr_name = set_capture_name(word, "attr_name")
local attr_name_in_path = "@" * attr_name
local attr_value = set_capture_name(value, "value")
local attr_relation = set_capture_name(m.C(m.S"!^$*"^-1 * "=") * space, "relation")
local attr_condition = collect_captures(attr_relation * attr_value, "condition")
local attr_path = set_capture_name(lpeg.C(AttrPath), "attr_path")
local attribute_filter = function_parser(collect_captures("[" * space * (attr_name + attr_path) * attr_condition^-1 * "]" * space), "filter_by_attribute")

local function_filter_name = set_capture_name(":" * space * word * space, "function_name")
local balanced_parentheses = lpeg.P{ "(" * ((m.P(1) - lpeg.S"()") + lpeg.V(1))^0 * ")" }
local argument_string = m.C(((m.P(1) - lpeg.S"()") + balanced_parentheses)^0)
local arguments = set_capture_name("(" * argument_string * ")" * space, "argument_string")
local function_filter = function_parser(collect_captures(function_filter_name * arguments^-1), "filter_with_function")

local role_name = set_capture_name("/" * word, "role_name")
local navigation = function_parser(collect_captures(role_name * space), "navigate")

local inv_role_name = set_capture_name("/inv(" * space * word * space * ")", "role_name")
local inv_navigate = function_parser(collect_captures(inv_role_name), "inv_navigate")

local filter = type_filter + attribute_filter + function_filter + inv_navigate + navigation

local intersection = function_parser(m.Ct(filter * filter^1 * space), "intersect_selectors") + filter;


local Selector = m.P{Union,
  Intersection = intersection;
  Union = function_parser(m.Ct(intersection * ("," * space * intersection)^1), "union_selectors") + intersection;
  AttrPath = function_parser(collect_captures(set_capture_name(intersection, "selector")^-1 * attr_name_in_path), "return_attr_value");
}

local Selector = space * Selector * -1

local parse_cache = {}
setmetatable(parse_cache, {__mode = "kv"})

function parse(selector)
  if parse_cache[selector] then
    return parse_cache[selector]
  else
    local parse_tree = m.match(Selector, selector)
    if not parse_tree then
      error("invalid selector string: " .. selector, 4)
    end
    parse_cache[selector] = parse_tree
    return parse_tree
  end
end


local attr_name_or_path_with_attr_name = collect_captures(attr_name + set_capture_name(lpeg.C(intersection), "path")^-1 * attr_name_in_path) * -1

local attr_selector_parse_cache = {}
setmetatable(attr_selector_parse_cache, {__mode = "kv"})

function parse_attr_selector(attr_selector)
  if attr_selector_parse_cache[attr_selector] then
    return attr_selector_parse_cache[attr_selector]
  else
    local parse_tree = m.match(attr_name_or_path_with_attr_name, attr_selector)
    if not parse_tree then
      error("invalid attr path string: " .. attr_selector, 4)
    end
    attr_selector_parse_cache[attr_selector] = parse_tree
    return parse_tree
  end
end

-- print(dumptable(m.match(m.Ct(m.Cc("id") * m.C(m.P"patt")), "patt")))

-- log(dumptable(m.match(Selector, "[u]")))
-- 
-- log(dumptable(m.match(Selector, "aoe")))
-- print(dumptable(m.match(Selector, "[aeo], b")))
-- print(dumptable(m.match(Selector, "[aeo], aoe   ,bbb, *")))
-- print(dumptable(m.match(Selector, "[aeo]")))
-- print(dumptable(m.match(Selector, "[aeo =  12  t  ]")))
-- print(dumptable(m.match(Selector, "[aeo != ' 12  t ' ]")))
-- 
-- print(dumptable(m.match(Selector, "[aeo  = 12] [aoeu],natohu, [uuu *= 'oeatuh']")))
-- 
-- print(dumptable(m.match(Selector, ":au(a,b,'aoeu )],')")))
-- 
-- print(dumptable(m.match(Selector, "b:au(a,b,'aoeu )[t]aoe,xxx")))
-- 
-- 
-- print(dumptable(m.match(Selector, "")))
--
-- log(dumptable(m.match(Selector, "/a:t(9)")))
-- print(dumptable(m.match(Selector, "/a:t(9)")))
-- 
--  
-- print(dumptable(m.match(Selector, "ao,*/b/c")))
-- 
-- print(dumptable(m.match(Selector, "a/b[t]/c")))
-- 
-- print(dumptable(m.match(Selector, "a,/b")))
-- print(dumptable(m.match(Selector, "a/b[t]/c")))
-- print(dumptable(m.match(Selector, "a/b:f,[u]/d")))

-- print(dumptable(m.match(Selector, ":f")))
-- print(dumptable(m.match(Selector, ":f(a)")))
-- print(dumptable(m.match(Selector, ":f( a,:12:y(t) )")))