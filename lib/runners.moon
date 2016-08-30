define = require'classy'.define
{:is_present} = require "fs"
{:merge, :concat} = table
{:round} = math
sha256 = require "sha256"
notify = _G.notify
gettimeofday = _G.gettimeofday
log = _G.log

expand_file = (data, file) ->
  return nil unless data
  data\gsub '([[{%<](file)[]}>])', file

(opts={}) ->

RunList = define 'RunList', ->
  properties
    runnables: =>
      [r for r in *@list when r.runnable]

    non_runnables: =>
      [r for r in *@list when not r.runnable]

  instance
    initialize: (...) =>
      @list = {...}

    id: (changed_file) =>
      sha256 concat(["#{changed_file}#{tostring(runner)}" for runner in *@list], "\n")

  meta
    __add: (other) =>
      newlist = {}
      for runner in *@list
        newlist[#newlist + 1] = runner
      for runner in *other.list
        newlist[#newlist + 1] = runner
      new unpack(newlist)

    __call: (changed_file, event_name) =>
      success = true
      ran = {}
      start = gettimeofday! / 1000.0
      non_runnables = @non_runnables
      runnables = @runnables

      for runner in *non_runnables
        log.debug "Skipping run for #{tostring(runner)}, changed_file: #{changed_file}, mapped_file: #{runner.mapped_file}, perhaps the mapped file is missing?"

      return nil, {} if #runnables == 0

      for runner in *runnables
        next unless runner.runnable
        :mapped_file, :name, :args = runner
        ev =
          :mapped_file
          :changed_file
          :name
          :args
          description: tostring runner

        notify.start ev
        runner.changed_file = changed_file
        success and= runner!
        ev.success = success
        ran[#ran + 1] = ev
        break unless success

      finish = gettimeofday! / 1000.0
      ran.elapsed_time = round finish - start, 3
      ran.id = @id changed_file
      ran.event_name = event_name
      ran.changed_file = changed_file

      notify.finish success, ran
      return success, ran

FunctionHandler = define 'FunctionHandler', ->
  accessors
    info: {'handler'}

  properties
    runnable: =>
      if @info.runnable
        return @info.runnable!
      true

    handler: =>
      @info.handler

    name: => @info.name or "#{@handler}"

  instance
    initialize: (file, info={}) =>
      @args = {file}
      @mapped_file = file
      @info = info

    to_run_list: => RunList.new @

  meta
    __tostring: =>
      "#{@name} #{@mapped_file}"

    __call: (info={}) =>
      info = merge info, changed_file: @changed_file, mapped_file: @mapped_file
      @.handler @mapped_file, info

function_handler = (file, info={}) -> FunctionHandler.new(file, info)\to_run_list!

func = (info={}) ->
  handler = assert info.handler, "handler key must be set when creating a function handler"
  only_if = info.only_if
  info.only_if = nil
  name = info.name
  (file) ->
    local runnable
    if only_if
      runnable = -> only_if file
    function_handler file, :handler, :name, :runnable

command = (cmd, opts={}) ->
  only_if = opts.only_if or is_present
  handler = (file, info={}) ->
    cmdline, replaced = expand_file cmd, file
    if replaced == 0
      cmdline = "#{cmd} #{file}"
    _, _, status = os.execute cmdline
    status == 0

  (file) -> 
    function_handler file, :handler, name: cmd, runnable: -> only_if file


:command, :func, :function_handler
