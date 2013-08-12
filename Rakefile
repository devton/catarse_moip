#!/usr/bin/env rake
begin
  require 'bundler/setup'
  require 'rspec/core/rake_task'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end
begin
  require 'rdoc/task'
rescue LoadError
  require 'rdoc/rdoc'
  require 'rake/rdoctask'
  RDoc::Task = Rake::RDocTask
end

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'CatarseMoip'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

Bundler::GemHelper.install_tasks
RSpec::Core::RakeTask.new(:spec)

task :jasmine do
  sh "jasmine-node spec/javascripts"
end

task default: [:spec, :jasmine]

