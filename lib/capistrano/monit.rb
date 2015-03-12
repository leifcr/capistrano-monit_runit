def try_require(library)
  require "#{library}"
  rescue LoadError => e
    puts "Capistrano / Base Helper: Cannot load library: #{library} Error: #{e}"
end

try_require 'capistrano/dsl/base_paths'
try_require 'capistrano/dsl/monit_paths'
try_require 'capistrano/helpers/base'
try_require 'capistrano/helpers/monit'
load File.expand_path('../tasks/base.rake', __FILE__)
load File.expand_path('../tasks/monit.rake', __FILE__)
