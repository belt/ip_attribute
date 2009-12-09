require 'pathname'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

DIR = Pathname.new(File.dirname(__FILE__))
desc 'Default: run unit tests.'
task :default => :test

desc 'Test the ip_attribute plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the ip_attribute plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'IpAttribute'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Remove old sqlite file.'
task :refresh_db do
  `rm -f #{File.dirname(__FILE__)}/test/acts_as_ip.sqlite3`
end

