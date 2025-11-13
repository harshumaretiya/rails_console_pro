# frozen_string_literal: true

# Global helper methods available in console
def schema(model_class)
  RailsConsolePro::Commands.schema(model_class)
end

def explain(relation_or_model, *args)
  RailsConsolePro::Commands.explain(relation_or_model, *args)
end

def navigate(model_or_string)
  pastel = RailsConsolePro::ColorHelper.pastel
  if model_or_string.is_a?(String)
    begin
      model = model_or_string.constantize
    rescue NameError
      puts pastel.red("Error: Could not find model '#{model_or_string}'")
      puts pastel.yellow("Make sure the model name is correct and loaded.")
      return nil
    end
  else
    model = model_or_string
  end

  unless RailsConsolePro::ModelValidator.valid_model?(model)
    puts pastel.red("Error: #{model} is not an ActiveRecord model")
    return nil
  end

  navigator = RailsConsolePro::AssociationNavigator.new(model)
  navigator.start
end

def stats(model_class)
  RailsConsolePro::Commands.stats(model_class)
end

def diff(object1, object2)
  RailsConsolePro::Commands.diff(object1, object2)
end

def profile(target = nil, *args, **kwargs, &block)
  RailsConsolePro::Commands.profile(target, *args, **kwargs, &block)
end

def jobs(options = {})
  RailsConsolePro::Commands.jobs(options)
end

def snippets(action = :list, *args, **kwargs, &block)
  RailsConsolePro::Commands.snippets(action, *args, **kwargs, &block)
end

def introspect(model_class, *options)
  RailsConsolePro::Commands.introspect(model_class, *options)
end

