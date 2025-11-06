# frozen_string_literal: true

namespace :rails_console_pro do
  desc "Display Rails Console Pro version"
  task :version do
    require_relative "../rails_console_pro/version"
    puts "Rails Console Pro version: #{RailsConsolePro::VERSION}"
  end
end

