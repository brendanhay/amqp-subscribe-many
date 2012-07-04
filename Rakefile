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
  gem.name = "the-perfect-gem"
  gem.homepage = "http://github.com/brendanhay/the-perfect-gem"
  gem.license = "MIT"
  gem.summary = %Q{TODO: one-line summary of your gem}
  gem.description = %Q{TODO: longer description of your gem}
  gem.email = "brendan.g.hay@gmail.com"
  gem.authors = ["brendanhay"]
  # dependencies defined in Gemfile
end

Jeweler::RubygemsDotOrgTasks.new

YARD::Rake::YardocTask.new
