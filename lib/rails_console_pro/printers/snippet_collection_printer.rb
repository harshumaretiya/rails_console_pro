# frozen_string_literal: true

module RailsConsolePro
  module Printers
    # Printer for snippet collection results
    class SnippetCollectionPrinter < BasePrinter
      PREVIEW_WIDTH = 80

      def print
        collection = value
        print_header(collection)

        if collection.empty?
          output.puts color(config.get_color(:warning), "No snippets yet. Capture one with snippets(:add, \"User.count\")")
        else
          collection.each_with_index do |snippet, index|
            print_row(snippet, index: index)
          end
        end

        print_footer(collection)
        collection
      end

      private

      def print_header(collection)
        border
        title = "📚 SNIPPETS"
        filters = []
        filters << "query: #{collection.query.inspect}" if collection.query
        filters << "tags: #{collection.tags.join(', ')}" if collection.tags.any?
        filters << "limit: #{collection.limit}" if collection.limit

        header_text = filters.any? ? "#{title} (#{filters.join(' · ')})" : title
        output.puts bold_color(config.get_color(:header), header_text)
        border
      end

      def print_row(snippet, index:)
        index_label = color(config.get_color(:info), (index + 1).to_s.rjust(2))
        id_label = bold_color(config.get_color(:attribute_key), snippet.id)
        tags_label = snippet.tags.any? ? color(config.get_color(:info), "[#{snippet.tags.join(', ')}]") : nil
        favorite_marker = snippet.favorite? ? color(config.get_color(:success), "★") : " "
        summary = truncate(snippet.summary)

        output.puts "#{index_label} #{favorite_marker} #{id_label} #{summary}"
        if tags_label
          output.puts color(:dim, "   #{tags_label}")
        end
      end

      def print_footer(collection)
        border
        output.puts color(:dim, "Showing #{collection.size} #{collection.size == 1 ? 'snippet' : 'snippets'}")
        border
      end

      def truncate(text)
        return '' unless text
        return text if text.length <= PREVIEW_WIDTH

        "#{text[0, PREVIEW_WIDTH - 1]}…"
      end
    end
  end
end

