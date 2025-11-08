# frozen_string_literal: true

# Pry command definitions
if defined?(Pry)
  Pry::Commands.create_command "schema" do
    description "Inspect database schema for a model"
    
    def process
      pastel = RailsConsolePro::ColorHelper.pastel
      unless RailsConsolePro.config.schema_command_enabled
        output.puts pastel.yellow("Schema command is disabled. Enable it with: RailsConsolePro.configure { |c| c.schema_command_enabled = true }")
        return
      end

      model_name = args.first
      if model_name.nil?
        output.puts pastel.red("Usage: schema ModelName")
        output.puts pastel.yellow("Example: schema User")
        return
      end
      
      begin
        model_class = model_name.constantize
        result = RailsConsolePro::Commands.schema(model_class)
        RailsConsolePro.call(output, result, pry_instance) if result
      rescue NameError => e
        output.puts pastel.red("Error: Could not find model '#{model_name}'")
        output.puts pastel.yellow("Make sure the model name is correct and loaded.")
      rescue => e
        output.puts pastel.red("Error: #{e.message}")
      end
    end
  end

  Pry::Commands.create_command "profile" do
    description "Profile a block, callable, or relation and report query stats"

    def process
      pastel = RailsConsolePro::ColorHelper.pastel
      unless RailsConsolePro.config.profile_command_enabled
        output.puts pastel.yellow("Profile command is disabled. Enable it with: RailsConsolePro.configure { |c| c.profile_command_enabled = true }")
        return
      end

      if args.empty?
        show_usage
        return
      end

      begin
        expression = args.join(' ')
        profile_target = eval(expression, target)
        result = RailsConsolePro::Commands.profile(profile_target)
        RailsConsolePro.call(output, result, pry_instance) if result
      rescue SyntaxError => e
        output.puts pastel.red("Syntax Error: #{e.message}")
        show_usage
      rescue => e
        output.puts pastel.red("Error: #{e.message}")
      end
    end

    private

    def show_usage
      pastel = RailsConsolePro::ColorHelper.pastel
      output.puts pastel.red("Usage: profile expression")
      output.puts pastel.yellow("Examples:")
      output.puts pastel.cyan("  profile User.active.limit(10)")
      output.puts pastel.cyan("  profile -> { User.includes(:posts).each { |u| u.posts.load } }")
      output.puts pastel.yellow("")
      output.puts pastel.yellow("Tip: For blocks, call the helper method directly: profile('Load') { User.limit(5).to_a }")
    end
  end

  Pry::Commands.create_command "explain" do
    description "Analyze SQL query execution plan"
    
    def process
      pastel = RailsConsolePro::ColorHelper.pastel
      unless RailsConsolePro.config.explain_command_enabled
        output.puts pastel.yellow("Explain command is disabled. Enable it with: RailsConsolePro.configure { |c| c.explain_command_enabled = true }")
        return
      end

      if args.empty?
        output.puts pastel.red("Usage: explain Model.where(...) or explain(Model, conditions)")
        return
      end
      
      begin
        relation = eval(args.join(' '), target)
        result = RailsConsolePro::Commands.explain(relation)
        output.puts result if result
      rescue => e
        output.puts pastel.red("Error: #{e.message}")
        output.puts pastel.yellow("💡 Use: explain(Model.where(...)) or explain(Model, key: value)")
      end
    end
  end

  Pry::Commands.create_command "navigate" do
    description "Navigate through model associations interactively"
    
    def process
      pastel = RailsConsolePro::ColorHelper.pastel
      unless RailsConsolePro.config.navigate_command_enabled
        output.puts pastel.yellow("Navigate command is disabled. Enable it with: RailsConsolePro.configure { |c| c.navigate_command_enabled = true }")
        return
      end

      model_name = args.first
      if model_name.nil?
        output.puts pastel.red("Usage: navigate ModelName")
        output.puts pastel.yellow("Example: navigate User")
        return
      end
      
      begin
        model = model_name.constantize
        navigator = RailsConsolePro::AssociationNavigator.new(model)
        navigator.start
      rescue ArgumentError => e
        output.puts pastel.red("Error: #{e.message}")
      end
    end
  end

  Pry::Commands.create_command "export" do
    description "Export data to JSON, YAML, or HTML file"
    
    def process
      pastel = RailsConsolePro::ColorHelper.pastel
      unless RailsConsolePro.config.export_enabled
        output.puts pastel.yellow("Export command is disabled. Enable it with: RailsConsolePro.configure { |c| c.export_enabled = true }")
        return
      end

      if args.empty?
        show_usage
        return
      end
      
      begin
        if args.size < 2
          show_usage
          return
        end
        
        # Simple parsing: export <data> <file_path> [format]
        file_path = args[-1].gsub(/^['"]|['"]$/, '')
        data_expr = args[0..-2].join(' ')
        
        format_keywords = %w[json yaml yml html htm]
        if args.size >= 3 && format_keywords.include?(args[-2].downcase)
          format = args[-2].downcase
          data_expr = args[0..-3].join(' ')
        else
          format = nil
        end
        
        data = eval(data_expr, target)
        result = RailsConsolePro::Commands.export(data, file_path, format: format)
        
        if result
          output.puts pastel.green("✅ Exported to: #{File.expand_path(result)}")
        else
          output.puts pastel.red("❌ Export failed")
        end
      rescue SyntaxError => e
        output.puts pastel.red("Syntax Error: #{e.message}")
        show_usage
      rescue => e
        output.puts pastel.red("Error: #{e.message}")
        output.puts pastel.yellow("💡 Tip: Make sure the data is exportable (schema result, explain result, ActiveRecord object, etc.)")
        show_usage
      end
    end
    
    private
    
    def show_usage
      pastel = RailsConsolePro::ColorHelper.pastel
      output.puts pastel.red("Usage: export <data> <file_path> [format]")
      output.puts pastel.yellow("")
      output.puts pastel.yellow("Examples:")
      output.puts pastel.cyan("  export schema(User) user_schema.json")
      output.puts pastel.cyan("  export User.first user.html html")
      output.puts pastel.cyan("  export explain(User.where(active: true)) query.json")
      output.puts pastel.cyan("  export User.all users.json")
      output.puts pastel.yellow("")
      output.puts pastel.yellow("Formats: json, yaml, html (auto-detected from file extension if not specified)")
      output.puts pastel.yellow("")
      output.puts pastel.dim("💡 Tip: You can also use methods directly:")
      output.puts pastel.dim("     schema(User).export_to_file('user.json')")
      output.puts pastel.dim("     User.first.export_to_file('user.html', format: 'html')")
    end
  end

  Pry::Commands.create_command "stats" do
    description "Show model statistics (record count, growth rate, table size, index usage)"
    
    def process
      pastel = RailsConsolePro::ColorHelper.pastel
      unless RailsConsolePro.config.stats_command_enabled
        output.puts pastel.yellow("Stats command is disabled. Enable it with: RailsConsolePro.configure { |c| c.stats_command_enabled = true }")
        return
      end

      model_name = args.first
      if model_name.nil?
        output.puts pastel.red("Usage: stats ModelName")
        output.puts pastel.yellow("Example: stats User")
        return
      end
      
      begin
        model_class = model_name.constantize
        result = RailsConsolePro::Commands.stats(model_class)
        RailsConsolePro.call(output, result, pry_instance) if result
      rescue NameError => e
        output.puts pastel.red("Error: Could not find model '#{model_name}'")
        output.puts pastel.yellow("Make sure the model name is correct and loaded.")
      rescue => e
        output.puts pastel.red("Error: #{e.message}")
      end
    end
  end

  Pry::Commands.create_command "diff" do
    description "Compare two objects and highlight differences"
    
    def process
      pastel = RailsConsolePro::ColorHelper.pastel
      unless RailsConsolePro.config.diff_command_enabled
        output.puts pastel.yellow("Diff command is disabled. Enable it with: RailsConsolePro.configure { |c| c.diff_command_enabled = true }")
        return
      end

      if args.empty?
        output.puts pastel.red("Usage: diff object1, object2")
        output.puts pastel.yellow("Examples:")
        output.puts pastel.cyan("  diff User.first, User.last")
        output.puts pastel.cyan("  diff user1, user2")
        output.puts pastel.cyan("  diff {a: 1}, {a: 2}")
        return
      end
      
      begin
        all_args = args.join(' ')
        parts = all_args.split(',').map(&:strip)
        
        if parts.size < 2
          output.puts pastel.red("Error: Need two objects to compare (separated by comma)")
          output.puts pastel.yellow("Usage: diff object1, object2")
          return
        end
        
        object1 = eval(parts[0], target)
        object2 = eval(parts[1], target)
        
        result = RailsConsolePro::Commands.diff(object1, object2)
        RailsConsolePro.call(output, result, pry_instance) if result
      rescue SyntaxError => e
        output.puts pastel.red("Syntax Error: #{e.message}")
        output.puts pastel.yellow("💡 Make sure to separate objects with a comma: diff object1, object2")
      rescue => e
        output.puts pastel.red("Error: #{e.message}")
        output.puts pastel.yellow("💡 Use: diff object1, object2")
      end
    end
  end

  # Add aliases
  begin
    Pry.commands.alias_command 'nav', 'navigate'
    Pry.commands.alias_command 'n', 'navigate'
  rescue => e
    # Silently fail if aliases can't be registered
  end
end

