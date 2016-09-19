define = require'classy'.define

define 'Event', ->
  instance
    initialize: (type, data={}) =>
      @type = type
      for k, v in pairs data
        continue if k == 'type'
        @[k] = v
