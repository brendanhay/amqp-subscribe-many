# This Source Code Form is subject to the terms of
# the Mozilla Public License, v. 2.0.
# A copy of the MPL can be found in the LICENSE file or
# you can obtain it at http://mozilla.org/MPL/2.0/.
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

task :default => :console

task :console do
  sh "irb -rubygems -I lib -r messaging.rb"
end
