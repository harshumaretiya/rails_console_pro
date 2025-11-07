# frozen_string_literal: true

# Pry integration - sets up Pry hooks
if defined?(Pry)
  Pry.config.print = proc do |output, value, pry_instance|
    RailsConsolePro.call(output, value, pry_instance)
  end
end

