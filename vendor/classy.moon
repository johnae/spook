-- (The MIT License)

-- Copyright (c) 2016 John Axel Eriksson <john@insane.se>

-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- 'Software'), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:

-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- See https://github.com/johnae/classy for more

merge = table.merge or (t1, t2) ->
  res = {k, v for k, v in pairs t1}
  for k, v in pairs t2
    res[k] = v
  res

copy_value = (copies) =>
  return @ unless type(@) == 'table'
  return copies[@] if copies and copies[@]
  copies or= {}
  copy = setmetatable {}, getmetatable @
  copies[@] = copy
  for k, v in pairs @
    copy[copy_value(k, copies)] = copy_value v, copies
  copy

{
  :copy_value
  define: (name, class_initializer) ->
    local parent_class
    __instance = {}
    __properties = {}
    is_a = {}
    __meta = {}
    new_class = __type: name, :__properties, :is_a, :__instance, :__meta

    new = (...) ->
      new_instance = setmetatable {}, __meta
      new_instance.initialize new_instance, ...
      new_instance

    default_function_env = setmetatable {:new}, __index: _G

    static = (opts) ->
      for name, def in pairs opts
        if type(def) == 'function'
          setfenv def, default_function_env
        new_class[name] = def

    instance = (opts) ->
      for name, def in pairs opts
        if type(def) == 'function'
          setfenv def, default_function_env
        __instance[name] = def

    include = instance -- same thing, different name

    parent = (parent) -> parent_class = parent

    missing_prop =
      get: (k) => rawget @, k
      set: (k, v) => rawset @, k, v
    missing_property = (def) -> missing_prop = merge missing_prop, def

    properties = (opts={}) ->
      for k, v in pairs opts
        if type(v) == 'function'
          v = get: v
        if old_prop = __properties[k]
          v = merge(old_prop, v)
        __properties[k] = v

    accessors = (opts={}) ->
      for field, keys in pairs opts
        for key in *keys
          __properties[key] =
            get: => @[field][key]
            set: (v) => @[field][key] = v

    meta = (opts={}) ->
      for name, def in pairs opts
        if type(def) == 'function'
          setfenv def, default_function_env
        __meta[name] = def

    class_initializer_env = setmetatable {
      :include
      :parent
      :instance
      :properties
      :accessors
      :meta
      :static
      :missing_property
      self: new_class
    }, __index: _G

    setfenv class_initializer, class_initializer_env
    class_initializer new_class

    is_a[new_class] = true
    __instance.is_a = is_a
    __instance.__type = name
    __instance.dup = copy_value
    -- inherit parent if defined
    if parent_class
      for k, v in pairs parent_class.is_a
        is_a[k] = v
      for name, def in pairs parent_class
        new_class[name] = def unless new_class[name]
      for name, def in pairs parent_class.__properties
        __properties[name] = def unless __properties[name]
      for name, def in pairs parent_class.__instance
        if new_def = __instance[name]
          -- this enables calling "super" in a function to
          -- run the same name function from parent
          if type(new_def) == 'function'
            env = copy_value default_function_env -- also includes 'new' as directly callable
            env.super = def
            setfenv new_def, env
        else
          __instance[name] = def
        __instance[name] = def unless __instance[name]
      for name, def in pairs parent_class.__meta
        __meta[name] = def unless __meta[name]

    __meta.__index = (k) =>
      if v = rawget __instance, k
        return v
      -- next try properties
      if prop = rawget __properties, k
        -- check if the property has getter defined
        if type(prop) == 'table'
          return prop.get @, k if prop.get
        -- finally just return the property as is if no getter
        return prop
      missing_prop.get @, k if missing_prop.get

    __meta.__newindex = (k, v) =>
      -- first try setting properties
      if prop = rawget __properties, k
        if type(prop) == 'table'
          return prop.set @, v if prop.set
        -- if there were no setters/getters
        -- simply set the property directly
        __properties[k] = v
        return
      return missing_prop.set @, k, v if missing_prop.set
      rawset @, k, v

    __instance.initialize or= =>
    new_class.new = new
    new_class
}
