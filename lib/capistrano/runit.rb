def try_require(library)
  require "#{library}"
  rescue LoadError => e
    puts "Capistrano / Base Helper: Cannot load library: #{library} Error: #{e}"
end

try_require 'capistrano/dsl/base_paths'
try_require 'capistrano/dsl/runit_paths'
try_require 'capistrano/helpers/base'
try_require 'capistrano/helpers/runit'
try_require 'capistrano/base'
load File.expand_path('../tasks/runit.rake', __FILE__)
