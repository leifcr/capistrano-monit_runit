def try_require(library)
  begin
    require "#{library}"
  rescue LoadError => e
    puts "Capistrano-Base Helper: Cannot load library: #{library} Error: #{e}"
  end
end

try_require 'capistrano-base_helper/base_helper'
try_require 'capistrano-base_helper/runit_base'
try_require 'capistrano-base_helper/monit_base'
