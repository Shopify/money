# encoding: utf-8
# frozen_string_literal: true

begin
  require 'bundler/gem_tasks'
rescue LoadError
  nil
end

require 'rubygems'
require 'bundler'
require 'rdoc/task'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit(e.status_code)
end
require 'rake'

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

namespace :rbs do
  desc "Install RBS collection"
  task :install do
    sh "rbs collection install > /dev/null"
  end

  desc "Validate RBS type signatures"
  task validate: :install do
    sh "rbs -I sig validate"
  end

  desc "List RBS files"
  task :list do
    sh "find sig -name '*.rbs'"
  end
end

namespace :steep do
  desc "Type check Ruby code against RBS signatures"
  task check: "rbs:install" do
    sh "steep check"
  end
end

desc "Run all type checks (RBS validation + Steep type checking)"
task typecheck: ["rbs:validate", "steep:check"]

task default: [:spec, :typecheck]

require 'rake/task'
RDoc::Task.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "money #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
