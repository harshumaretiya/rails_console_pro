# frozen_string_literal: true

module RailsConsolePro
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc "Creates a Rails Console Pro initializer file"

      def create_initializer
        template "rails_console_pro.rb", "config/initializers/rails_console_pro.rb"
      end
    end
  end
end

