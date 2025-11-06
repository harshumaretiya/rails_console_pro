# frozen_string_literal: true

module RailsConsolePro
  # Rails integration via Railtie
  class Railtie < Rails::Railtie
    # Auto-load Rails Console Pro when Rails starts
    # The initializer.rb file handles the actual setup
    config.after_initialize do
      # Ensure Pry hook is set (in case Pry loads after the gem)
      if defined?(Pry)
        # Wrap in a proc that handles errors gracefully
        Pry.config.print = proc do |output, value, pry_instance|
          begin
            RailsConsolePro.call(output, value, pry_instance)
          rescue => e
            # Fallback to default Pry printing if our printer fails
            if Rails.env.development? || ENV['RAILS_CONSOLE_PRO_DEBUG']
              output.puts Pastel.new.red.bold("💥 RailsConsolePro Error in Pry hook: #{e.class}: #{e.message}")
              output.puts Pastel.new.dim(e.backtrace.first(3).join("\n"))
            end
            Pry::ColorPrinter.default(output, value, pry_instance)
          end
        end
        Rails.logger&.debug("Rails Console Pro: Pry integration active")
      end
    end
  end
end
