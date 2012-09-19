#
# Bundler
#

require "rubygems"
require "bundler"

begin
  Bundler.setup(:default)
rescue Bundler::BundlerError => ex
  $stderr.puts ex.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit ex.status_code
end


#
# Tests
#

require "rake"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "lib"
  t.test_files = FileList["test/*_test.rb"]
  t.verbose = true
end

task :default => :test


#
# Console
#

task :console do
  sh "irb -rubygems -I lib -r messaging.rb"
end


#
# Gemify
#

require "jeweler"

Jeweler::RubygemsDotOrgTasks.new

Jeweler::Tasks.new do |gem|
  gem.name        = "amqp-subscribe-many"
  gem.version     = "0.1.6"
  gem.homepage    = "http://github.com/brendanhay/amqp-subscribe-many"
  gem.license     = "MPL"
  gem.summary     = "An implementation of the publish one, subscribe many pattern"
  gem.description = "Codifies best practices and configuration when consuming from multiple AMQP brokers simultaneously"
  gem.email       = "brendan@soundcloud.com"
  gem.authors     = ["brendanhay"]
end


#
# Docs
#

require "yard"

YARD::Rake::YardocTask.new
