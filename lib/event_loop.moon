os = require'syscall'.abi.os
system = os == 'linux' and 'linux' or 'bsd'
require "#{system}.event_loop"
