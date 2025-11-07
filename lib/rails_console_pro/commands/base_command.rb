# frozen_string_literal: true

module RailsConsolePro
  module Commands
    # Base class for commands with shared functionality
    class BaseCommand
      include ColorHelper

      protected

      def pastel
        RailsConsolePro::ColorHelper.pastel
      end
    end
  end
end

