# frozen_string_literal: true

module RailsConsolePro
  # Command methods for schema inspection and SQL explain
  # Thin facade that delegates to command classes
  module Commands
    extend self

    # Schema inspection command
    def schema(model_class)
      SchemaCommand.new.execute(model_class)
    end

    # SQL explain command
    def explain(relation_or_model, *args)
      ExplainCommand.new.execute(relation_or_model, *args)
    end

    # Export data to file (works with any exportable object)
    def export(data, file_path, format: nil)
      ExportCommand.new.execute(data, file_path, format: format)
    end

    # Model statistics command
    def stats(model_class)
      StatsCommand.new.execute(model_class)
    end

    # Object comparison command
    def diff(object1, object2)
      DiffCommand.new.execute(object1, object2)
    end

  # Profiling command
  def profile(target = nil, *args, **kwargs, &block)
    ProfileCommand.new.execute(target, *args, **kwargs, &block)
  end

    # Queue insights command
    def jobs(options = {})
      JobsCommand.new.execute(options)
    end

    # Snippets command
    def snippets(action = :list, *args, **kwargs, &block)
      SnippetsCommand.new.execute(action, *args, **kwargs, &block)
    end

    # Model introspection command
    def introspect(model_class, *options)
      IntrospectCommand.new.execute(model_class, *options)
    end
  end
end
