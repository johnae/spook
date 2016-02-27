{:is_present} = require "fs"
{:merge, :concat} = table
{:round} = math
sha256 = require "sha256"
notify = _G.notify
gettimeofday = _G.gettimeofday

expand_file = (data, file) ->
  return nil unless data
  data\gsub '([[{%<](file)[]}>])', file

(opts={}) ->

list = (...) ->
  runners = {...}
  runners.id = (changed_file) ->
    sha256 concat(["#{changed_file}#{tostring(runner)}" for runner in *runners], "\n")

  setmetatable runners, {
    __add: (list1, list2) ->
      newlist = {}
      for runner in *list1
        newlist[#newlist + 1] = runner
      for runner in *list2
        newlist[#newlist + 1] = runner
      list unpack(newlist)

    __call: (t, changed_file, event_name) ->
      success = true
      ran = {}
      start_time = gettimeofday! / 1000.0
      for runner in *runners
        {:mapped_file, :name, :args} = runner
        ev = {
          :mapped_file,
          :name,
          :args,
          description: tostring(runner)
        }
        notify.start(ev)
        success and= runner!
        ev.success = success
        ran[#ran + 1] = ev
        break unless success

      end_time = gettimeofday! / 1000.0
      ran.elapsed_time = round end_time - start_time, 3
      ran.id = sha256 concat(["#{changed_file}#{tostring(runner)}" for runner in *runners], "\n")
      ran.event_name = event_name
      ran.changed_file = changed_file

      notify.finish(success, ran)
      return success, ran
  }

function_handler = (file, info={}) ->
  fh = setmetatable {
    args: {file},
    handler: info.handler,
    mapped_file: file
    name: (info.name or "#{info.handler}")
  }, {
      __tostring: (t) ->
        name = info.name or "#{info.handler}"
        "#{name} #{t.mapped_file}"

      __call: (t, info={}) ->
        info = merge(info, changed_file: t.changed_file, mapped_file: t.mapped_file)
        t.handler unpack(t.args), info
  }
  list fh

func = (info={}) ->
  handler = assert(info.handler, "handler key must be set when creating a function handler")
  name = info.name
  (file) -> function_handler(file, :handler, :name)

command = (cmd, opts={}) ->
  only_if = opts.only_if or is_present
  handler = (file, info={}) ->
    cmdline, replaced = expand_file cmd, file
    if replaced == 0
      cmdline = "#{cmd} #{file}"

    unless only_if file
      return

    _, _, status = os.execute cmdline
    status == 0

  (file) -> function_handler(file, :handler, name: cmd)


:command, :func, :function_handler
