return {
  whitelist_globals = {
    ["."] = {
      'on_changed',
      'on_deleted',
      'on_created',
      'on_moved',
      'watch',
      'watchnr',
      'watch_file',
      'notifier',
      'log_level',
      'first_match_only',
      'one_fs_handler_at_a_time'
    },
    ["lib/config.moon"] = {
      'log_level',
      'notifier'
    },
    ["lib"] = {
      'properties',
      'static',
      'instance',
      'accessors',
      'new',
      'super',
      'missing_property',
      'parent',
      'meta'
    },
    ["spec"] = {
      'it', 'describe', 'before_each', 'before', 'after', 'after_each',
      'raise', 'spy', 'context', 'create_file', 'moon', 'run_loop'
    },
    ["spec/spec_helper.moon"] = {
      'uv'
    },
    ["spec/globals_spec.moon"] = {
      'getcwd', 'chdir'
    },
  }
}
