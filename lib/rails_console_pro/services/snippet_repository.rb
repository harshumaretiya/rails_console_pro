# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require 'securerandom'

module RailsConsolePro
  module Services
    # Persistence layer for console snippets
    class SnippetRepository
      include Enumerable

      DEFAULT_LIMIT = 20

      def initialize(store_path:)
        @store_path = File.expand_path(store_path)
      end

      def each(&block)
        all.each(&block)
      end

      def all(limit: nil)
        snippets = load_snippets.values.sort_by(&:updated_at).reverse
        limit ? snippets.first(limit) : snippets
      end

      def find(id)
        load_snippets[normalize_id(id)]
      end

      def search(term: nil, tags: nil, limit: nil)
        snippets = all
        term_value = normalize_query(term)
        tag_value = normalize_tags(tags)

        filtered = snippets.select do |snippet|
          snippet.matches?(term: term_value, tags: tag_value)
        end

        {
          results: limit ? filtered.first(limit) : filtered,
          total_count: filtered.size
        }
      end

      def add(body:, id: nil, tags: nil, description: nil, favorite: false, metadata: nil)
        snippet = Snippets::Snippet.new(
          id: id || generate_id(description: description, body: body),
          body: body,
          tags: tags,
          description: description,
          created_at: Time.now,
          updated_at: Time.now,
          favorite: favorite,
          metadata: metadata
        )

        persist(snippet)
        snippet
      end

      def update(id, **attributes)
        snippet = find(id)
        return unless snippet

        updated_snippet = snippet.with(**attributes.merge(updated_at: Time.now))
        persist(updated_snippet)
        updated_snippet
      end

      def delete(id)
        normalized_id = normalize_id(id)
        data = load_data
        return false unless data.key?(normalized_id)

        data.delete(normalized_id)
        write_data(data)
        true
      end

      def clear
        write_data({})
      end

      private

      attr_reader :store_path

      def persist(snippet)
        data = load_data
        data[snippet.id] = serialize(snippet)
        write_data(data)
        snippet
      end

      def load_snippets
        load_data.transform_values { |attrs| deserialize(attrs) }
      end

      def load_data
        return {} unless File.exist?(store_path)

        YAML.safe_load(File.read(store_path), permitted_classes: [Time], aliases: true) || {}
      rescue Psych::SyntaxError
        {}
      end

      def write_data(data)
        FileUtils.mkdir_p(File.dirname(store_path))

        File.open(store_path, File::RDWR | File::CREAT, 0o600) do |file|
          file.flock(File::LOCK_EX)
          file.rewind
          file.truncate(0)
          file.write(data.to_yaml)
          file.flush
        ensure
          file.flock(File::LOCK_UN)
        end

        true
      end

      def serialize(snippet)
        {
          'id' => snippet.id,
          'body' => snippet.body,
          'tags' => snippet.tags,
          'description' => snippet.description,
          'created_at' => snippet.created_at.utc.iso8601,
          'updated_at' => snippet.updated_at.utc.iso8601,
          'favorite' => snippet.favorite?,
          'metadata' => snippet.metadata
        }
      end

      def deserialize(attrs)
        Snippets::Snippet.new(
          id: attrs['id'],
          body: attrs['body'],
          tags: attrs['tags'],
          description: attrs['description'],
          created_at: attrs['created_at'],
          updated_at: attrs['updated_at'],
          favorite: attrs['favorite'],
          metadata: attrs['metadata']
        )
      end

      def normalize_id(id)
        id.to_s.strip.downcase.gsub(/\s+/, '-')
      end

      def normalize_query(term)
        return if term.nil?
        term.to_s.strip.downcase
      end

      def normalize_tags(tags)
        return if tags.nil?
        Array(tags).compact.map { |tag| tag.to_s.strip.downcase }.reject(&:empty?)
      end

      def generate_id(description:, body:)
        base =
          if description && !description.strip.empty?
            description
          else
            body.to_s.lines.first.to_s.strip
          end

        slug = base.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')
        slug = slug[0, 40] if slug.length > 40
        slug = "snippet-#{SecureRandom.hex(4)}" if slug.empty?

        existing_ids = load_data.keys
        candidate = slug
        suffix = 1
        while existing_ids.include?(candidate)
          suffix += 1
          candidate = "#{slug}-#{suffix}"
        end

        candidate
      end
    end
  end
end


