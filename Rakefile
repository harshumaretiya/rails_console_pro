# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task" if defined?(RuboCop)

RuboCop::RakeTask.new if defined?(RuboCop)

task default: :spec

