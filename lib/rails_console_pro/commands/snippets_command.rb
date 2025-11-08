# frozen_string_literal: true

module RailsConsolePro
  module Commands
    # Command for managing, searching, and listing reusable console snippets
    class SnippetsCommand < BaseCommand
      DEFAULT_LIST_LIMIT = 10

      def execute(action = :list, *args, **kwargs, &block)
        return disabled_message unless enabled?

        action = infer_action(action, args)
        case action
        when :list
          list_snippets(**kwargs)
        when :search
          search_snippets(*args, **kwargs)
        when :add, :create
          add_snippet(*args, **kwargs, &block)
        when :show
          show_snippet(*args)
        when :delete, :remove
          delete_snippet(*args)
        when :favorite
          toggle_favorite(*args, value: true)
        when :unfavorite
          toggle_favorite(*args, value: false)
        else
          pastel.red("Unknown snippets action: #{action}")
        end
      rescue ArgumentError => e
        pastel.red("Snippets error: #{e.message}")
      end

      private

      def enabled?
        RailsConsolePro.config.enabled && RailsConsolePro.config.snippets_command_enabled
      end

      def disabled_message
        pastel.yellow('Snippets command is disabled. Enable via RailsConsolePro.configure { |c| c.snippets_command_enabled = true }')
      end

      def infer_action(action, args)
        return action.to_sym if action.respond_to?(:to_sym)
        return :search if args.any?

        :list
      end

      def list_snippets(limit: DEFAULT_LIST_LIMIT, favorites: false)
        snippets = repository.all(limit: limit)
        snippets = snippets.select(&:favorite?) if favorites

        Snippets::CollectionResult.new(
          snippets: snippets,
          limit: limit,
          total_count: repository.all.size,
          tags: favorites ? ['favorite'] : []
        )
      end

      def search_snippets(term = nil, tags: nil, limit: DEFAULT_LIST_LIMIT)
        search_result = repository.search(term: term, tags: tags, limit: limit)
        snippets = search_result[:results]
        Snippets::CollectionResult.new(
          snippets: snippets,
          query: term,
          tags: Array(tags),
          limit: limit,
          total_count: search_result[:total_count]
        )
      end

      def add_snippet(body = nil, id: nil, tags: nil, description: nil, favorite: false, metadata: nil, &block)
        snippet_body = extract_body(body, &block)

        snippet = repository.add(
          body: snippet_body,
          id: id,
          tags: tags,
          description: description,
          favorite: favorite,
          metadata: metadata
        )

        Snippets::SingleResult.new(snippet: snippet, action: :add, created: true)
      end

      def show_snippet(id)
        snippet = repository.find(id)
        return pastel.yellow("No snippet found for '#{id}'") unless snippet

        Snippets::SingleResult.new(snippet: snippet, action: :show, created: false)
      end

      def delete_snippet(id)
        if repository.delete(id)
          pastel.green("Removed snippet '#{id}'")
        else
          pastel.yellow("No snippet found for '#{id}'")
        end
      end

      def toggle_favorite(id, value:)
        snippet = repository.update(id, favorite: value)
        return pastel.yellow("No snippet found for '#{id}'") unless snippet

        status = value ? 'marked as favorite' : 'removed from favorites'
        message = pastel.green("Snippet '#{id}' #{status}.")
        Snippets::SingleResult.new(
          snippet: snippet,
          action: value ? :favorite : :unfavorite,
          created: false,
          message: message
        )
      end

      def extract_body(body, &block)
        content = if block
                    result = block.call
                    result.respond_to?(:join) ? result.join("\n") : result.to_s
                  else
                    body
                  end

        raise ArgumentError, 'Snippet body is required' if content.nil? || content.to_s.strip.empty?

        content.to_s
      end

      def repository
        @repository ||= RailsConsolePro::Services::SnippetRepository.new(
          store_path: RailsConsolePro.config.snippet_store_path
        )
      end
    end
  end
end

