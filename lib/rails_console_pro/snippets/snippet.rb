# frozen_string_literal: true

require 'time'

module RailsConsolePro
  module Snippets
    # Represents a single snippet record persisted to disk
    class Snippet
      attr_reader :id, :body, :tags, :description, :created_at, :updated_at, :favorite, :metadata

      def initialize(id:, body:, tags: nil, description: nil, created_at: nil, updated_at: nil, favorite: false, metadata: nil)
        @id = normalize_id(id)
        @body = normalize_body(body)
        @tags = normalize_tags(tags)
        @description = description&.strip
        @created_at = normalize_time(created_at)
        @updated_at = normalize_time(updated_at || created_at)
        @favorite = !!favorite
        @metadata = metadata.is_a?(Hash) ? metadata.transform_keys(&:to_sym).freeze : {}.freeze
        @tags_for_search = @tags.map(&:downcase).freeze
        @searchable_values = begin
          values = [@id, @description, @body].compact
          values.concat(@tags_for_search)
          values.map { |val| val.to_s.downcase }.freeze
        end
        freeze
      end

      def favorite?
        favorite
      end

      def with(**attributes)
        self.class.new(**to_h.merge(attributes))
      end

      def matches?(term:, tags: nil)
        matches_term = term.nil? || term.empty? || searchable_values.any? { |value| value.include?(term.downcase) }
        matches_tags =
          if tags.nil? || tags.empty?
            true
          else
            desired_tags = Array(tags).compact.map { |tag| tag.to_s.downcase }.uniq
            snippet_tags = tags_for_search
            desired_tags.all? { |tag| snippet_tags.include?(tag) }
          end

        matches_term && matches_tags
      end

      def summary
        first_line = body.lines.first&.strip || ''
        descriptor = description || first_line
        descriptor = descriptor[0..96] + '…' if descriptor && descriptor.length > 97
        descriptor || id
      end

      def to_h
        {
          id: id,
          body: body,
          tags: tags.dup,
          description: description,
          created_at: created_at,
          updated_at: updated_at,
          favorite: favorite,
          metadata: metadata.dup
        }
      end

      private

      def normalize_id(value)
        value.to_s.strip.downcase.gsub(/\s+/, '-')
      end

      def normalize_body(value)
        body = value.respond_to?(:call) ? value.call.to_s : value.to_s
        raise ArgumentError, 'Snippet body cannot be empty' if body.strip.empty?
        body
      end

      def normalize_tags(value)
        Array(value).compact.map { |tag| tag.to_s.strip.downcase }.reject(&:empty?).uniq.freeze
      end

      def normalize_time(value)
        case value
        when Time
          value
        when String
          begin
            Time.parse(value)
          rescue ArgumentError
            Time.now
          end
        else
          Time.now
        end
      end

      def searchable_values
        @searchable_values
      end

      def tags_for_search
        @tags_for_search
      end
    end
  end
end

