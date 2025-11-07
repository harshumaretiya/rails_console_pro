# frozen_string_literal: true

module RailsConsolePro
  module Commands
    class ExportCommand < BaseCommand
      def execute(data, file_path, format: nil)
        return nil if data.nil?
        
        FormatExporter.export_to_file(data, file_path, format: format)
      rescue => e
        RailsConsolePro::ErrorHandler.handle(e, context: :export)
      end
    end
  end
end

