# frozen_string_literal: true

module RailsConsolePro
  module Snippets
    # Value object representing a filtered/listed set of snippets
    class CollectionResult
      include Enumerable

      attr_reader :snippets, :query, :tags, :limit, :total_count

      def initialize(snippets:, query: nil, tags: nil, limit: nil, total_count: nil)
        @snippets = Array(snippets)
        @query = query
        @tags = Array(tags).compact
        @limit = limit
        @total_count = total_count || @snippets.length
      end

      def each(&block)
        snippets.each(&block)
      end

      def size
        snippets.size
      end

      def empty?
        snippets.empty?
      end

      def metadata
        {
          query: query,
          tags: tags,
          limit: limit,
          total_count: total_count
        }
      end
    end
  end
end




