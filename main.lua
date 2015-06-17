require("lib")
local lpeg = require("lpeglj")
package.loaded['lpeg'] = lpeg
require("moonscript")
local to_lua = require("moonscript.base").to_lua
local status, filter = pcall(function()
  local f = io.open(".spook", "rb")
  local content = f:read("*all")
  f:close()
  local lua_code, line_table = to_lua(content)
  local chunk = loadstring(lua_code)
  return chunk()
end)
if not status then
  filter = function(file)
    return file
  end
end
local uv = require("uv")

local watch_dirs = {}
local line
for line in io.lines() do
  line, _ = line:gsub("/$", "", 1)
  table.insert(watch_dirs, line)
end
table.remove(argv, 1)
local utility = nil
if #argv >= 1  then
  utility = table.concat(argv, ' ')
end

local function run_utility(changed_file)
  if not utility then
    io.stdout:write("No utility to run, please supply it via arguments", "\n")
    return false
  end
  local output = io.popen(utility..' ' .. filter(changed_file))
  local line
  while true do
    local line = output:read()
    if line == nil then break end
    io.write(line)
    io.write("\n")
    io.flush()
  end
  output:close()
end

local last_changed_file = {"", true, 1}

local function create_event_handler(fse)
  return function(self, filename, events, status)
    local changed_file = fse:getpath() .. "/" .. filename
    last_changed_file = {changed_file, false, last_changed_file[3]+1}
    local timer = uv.new_timer()
    timer:start(200, 0, function()
      local changed_file = last_changed_file[1]
      local event_recorded = last_changed_file[2]
      local event_id = last_changed_file[3]
      last_changed_file[2] = true
      if not event_recorded then
        io.stdout:write(changed_file, "\n")
        run_utility(changed_file)
      end
      timer:close()
    end)
  end
end

for i, watch_dir in ipairs(watch_dirs) do
  print("watch_dir: "..watch_dir)
  local fse = uv.new_fs_event()
  fse:start(watch_dir, {recursive = true, stat = true}, create_event_handler(fse))
end

uv.run()
