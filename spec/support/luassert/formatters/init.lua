-- module will not return anything, only register formatters with the main assert engine
local assert = require('luassert.assert')
local ok, term = pcall(require, 'term')

local colors = setmetatable({
  none = function(c) return c end
},{ __index = function(self, key)
  if not ok or not term.isatty(io.stdout) or not term.colors then
    return function(c) return c end
  end
  return function(c)
    for token in key:gmatch("[^%.]+") do
      c = term.colors[token](c)
    end
    return c
  end
end
})

local function fmt_string(arg)
  if type(arg) == "string" then
    return string.format("(string) '%s'", arg)
  end
end

-- A version of tostring which formats numbers more precisely.
local function tostr(arg)
  if type(arg) ~= "number" then
    return tostring(arg)
  end

  if arg ~= arg then
    return "NaN"
  elseif arg == 1/0 then
    return "Inf"
  elseif arg == -1/0 then
    return "-Inf"
  end

  local str = string.format("%.20g", arg)

  if math.type and math.type(arg) == "float" and not str:find("[%.,]") then
    -- Number is a float but looks like an integer.
    -- Insert ".0" after first run of digits.
    str = str:gsub("%d+", "%0.0", 1)
  end

  return str
end

local function fmt_number(arg)
  if type(arg) == "number" then
    return string.format("(number) %s", tostr(arg))
  end
end

local function fmt_boolean(arg)
  if type(arg) == "boolean" then
    return string.format("(boolean) %s", tostring(arg))
  end
end

local function fmt_nil(arg)
  if type(arg) == "nil" then
    return "(nil)"
  end
end

local type_priorities = {
  number = 1,
  boolean = 2,
  string = 3,
  table = 4,
  ["function"] = 5,
  userdata = 6,
  thread = 7
}

local function is_in_array_part(key, length)
  return type(key) == "number" and 1 <= key and key <= length and math.floor(key) == key
end

local function get_sorted_keys(t)
  local keys = {}
  local nkeys = 0

  for key in pairs(t) do
    nkeys = nkeys + 1
    keys[nkeys] = key
  end

  local length = #t

  local function key_comparator(key1, key2)
    local type1, type2 = type(key1), type(key2)
    local priority1 = is_in_array_part(key1, length) and 0 or type_priorities[type1] or 8
    local priority2 = is_in_array_part(key2, length) and 0 or type_priorities[type2] or 8

    if priority1 == priority2 then
      if type1 == "string" or type1 == "number" then
        return key1 < key2
      elseif type1 == "boolean" then
        return key1  -- put true before false
      end
    else
      return priority1 < priority2
    end
  end

  table.sort(keys, key_comparator)
  return keys, nkeys
end

local function fmt_table(arg, fmtargs)
  if type(arg) ~= "table" then
    return
  end

  local tmax = assert:get_parameter("TableFormatLevel")
  local showrec = assert:get_parameter("TableFormatShowRecursion")
  local errchar = assert:get_parameter("TableErrorHighlightCharacter") or ""
  local errcolor = assert:get_parameter("TableErrorHighlightColor") or "none"
  local crumbs = fmtargs and fmtargs.crumbs or {}

  local function ft(t, l, cache)
    local cache = cache or {}
    if showrec and cache[t] and cache[t] > 0 then
      return "{ ... recursive }"
    end

    if next(t) == nil then
      return "{ }"
    end

    if l > tmax and tmax >= 0 then
      return "{ ... more }"
    end

    local result = "{"
    local keys, nkeys = get_sorted_keys(t)

    cache[t] = (cache[t] or 0) + 1

    for i = 1, nkeys do
      local k = keys[i]
      local v = t[k]

      if type(v) == "table" then
        v = ft(v, l + 1, cache)
      elseif type(v) == "string" then
        v = "'"..v.."'"
      end

      local crumb = crumbs[#crumbs - l + 1]
      local ch = (crumb == k and errchar or "")
      local indent = string.rep(" ",l * 2 - ch:len())
      local mark = (ch:len() == 0 and "" or colors[errcolor](ch))
      result = result .. string.format("\n%s%s[%s] = %s", indent, mark, tostr(k), tostr(v))
    end

    cache[t] = cache[t] - 1

    return result .. " }"
  end

  return "(table) " .. ft(arg, 1)
end

local function fmt_function(arg)
  if type(arg) == "function" then
    local debug_info = debug.getinfo(arg)
    return string.format("%s @ line %s in %s", tostring(arg), tostring(debug_info.linedefined), tostring(debug_info.source))
  end
end

local function fmt_userdata(arg)
  if type(arg) == "userdata" then
    return string.format("(userdata) '%s'", tostring(arg))
  end
end

local function fmt_thread(arg)
  if type(arg) == "thread" then
    return string.format("(thread) '%s'", tostring(arg))
  end
end

assert:add_formatter(fmt_string)
assert:add_formatter(fmt_number)
assert:add_formatter(fmt_boolean)
assert:add_formatter(fmt_nil)
assert:add_formatter(fmt_table)
assert:add_formatter(fmt_function)
assert:add_formatter(fmt_userdata)
assert:add_formatter(fmt_thread)
-- Set default table display depth for table formatter
assert:set_parameter("TableFormatLevel", 3)
assert:set_parameter("TableFormatShowRecursion", false)
assert:set_parameter("TableErrorHighlightCharacter", "*")
assert:set_parameter("TableErrorHighlightColor", "none")
