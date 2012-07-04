require "rubygems"
require "bundler"

begin
  Bundler.setup(:default)
rescue Bundler::BundlerError => ex
  $stderr.puts ex.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit ex.status_code
end

require "rake"
require "jeweler"
require "yard"

task :default => :console

task :console do
  sh "irb -rubygems -I lib -r messaging.rb"
end

Jeweler::Tasks.new do |gem|
  gem.name        = "amqp-subscribe-many"
  gem.version     = "0.1.0"
  gem.homepage    = "http://github.com/brendanhay/amqp-subscribe-many"
  gem.license     = "BSD"
  gem.summary     = %Q{TODO}
  gem.description = %Q{TODO}
  gem.email       = "brendan@soundcloud.com"
  gem.authors     = ["brendanhay"]
end

Jeweler::RubygemsDotOrgTasks.new

YARD::Rake::YardocTask.new
