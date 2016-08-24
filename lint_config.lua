return {
  whitelist_globals = {
    ["lib/config.moon"] = {
      'log_level',
      'notifier'
    },
    ["lib/runners.moon"] = {
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
      'raise', 'spy', 'context', 'run_uv_for', 'create_file', 'create_file_after',
      'update_file_after', 'delete_file_after'
    },
    ["spec/spec_helper.moon"] = {
      'uv'
    },
    ["spec/globals_spec.moon"] = {
      'getcwd', 'chdir'
    },
  }
}
