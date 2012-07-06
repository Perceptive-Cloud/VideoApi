require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rdoc/task'
require 'rspec/core/rake_task'

# TODO: Look at recent changes to Avarice Rakefile to avoid deprecation warnings

Rspec::Core::RakeTask.new(:spec) do |t|
end

### Version notes haved been moved to README.md

Rake::RDocTask.new do |rd|
  rd.rdoc_dir = "rdoc_html"
  rd.rdoc_files.include("lib/**/*.rb")
  rd.rdoc_files.exclude("**/*test*")
  rd.rdoc_files.exclude('multipart.rb')
end

