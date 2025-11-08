# frozen_string_literal: true

module RailsConsolePro
  module Snippets
    # Value object representing a single snippet lookup or creation
    class SingleResult
      attr_reader :snippet, :action, :created, :message

      def initialize(snippet:, action: :show, created: false, message: nil)
        @snippet = snippet
        @action = action
        @created = created
        @message = message
      end

      def created?
        !!created
      end

      def metadata
        {
          action: action,
          created: created?,
          message: message
        }
      end
    end
  end
end

