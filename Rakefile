# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'Run `bundle install` to install missing gems'
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = 'capistrano-monit_runit'
  gem.homepage = 'https://github.com/leifcr/capistrano-monit_runit'
  gem.license = 'MIT'
  gem.summary = 'Helpers for capistrano recipes using runit/monit'
  gem.description = 'Helpers for capistrano recipes using runit/monit. Currently: capistrano-puma and capistrano-delayed_job'
  gem.email = 'leifcr@gmail.com'
  gem.authors = ['Leif Ringstad']
  gem.files.exclude '.ruby-*'
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

# require 'rdoc/task'
# Rake::RDocTask.new do |rdoc|
#   version = File.exist?('VERSION') ? File.read('VERSION') : ""

#   rdoc.rdoc_dir = 'rdoc'
#   rdoc.title = "capistrano-empty #{version}"
#   rdoc.rdoc_files.include('README*')
#   rdoc.rdoc_files.include('lib/**/*.rb')
# end
