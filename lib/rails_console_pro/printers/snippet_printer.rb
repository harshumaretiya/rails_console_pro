# frozen_string_literal: true

module RailsConsolePro
  module Printers
    # Printer for individual snippet results
    class SnippetPrinter < BasePrinter
      def print
        result = value
        snippet = result.snippet

        border
        header_text = header_title(result)
        output.puts bold_color(config.get_color(:header), header_text)
        border

        output.puts format_metadata(snippet, result)
        output.puts

        snippet.body.each_line.with_index(1) do |line, number|
          output.puts format_line(number, line)
        end

        border
        output.puts result.message if result.message
        border

        snippet
      end

      private

      def header_title(result)
        case result.action
        when :add
          "✨ Captured snippet #{result.snippet.id}"
        when :favorite
          "⭐ Favorite snippet #{result.snippet.id}"
        when :unfavorite
          "☆ Snippet #{result.snippet.id}"
        else
          "📄 Snippet #{result.snippet.id}"
        end
      end

      def format_metadata(snippet, result)
        tags = snippet.tags.any? ? "tags: #{snippet.tags.join(', ')}" : nil
        details = []
        details << "description: #{snippet.description}" if snippet.description
        details << tags if tags
        details << "favorite: #{snippet.favorite?}"
        details << "created: #{snippet.created_at.strftime('%Y-%m-%d %H:%M')}"
        details << "updated: #{snippet.updated_at.strftime('%Y-%m-%d %H:%M')}"

        color(config.get_color(:info), details.compact.join(' · '))
      end

      def format_line(number, line)
        number_label = color(config.get_color(:attribute_key), number.to_s.rjust(3))
        "#{number_label} │ #{line.rstrip}"
      end
    end
  end
end

