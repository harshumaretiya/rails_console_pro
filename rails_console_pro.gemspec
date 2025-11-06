# frozen_string_literal: true

require_relative "lib/rails_console_pro/version"

Gem::Specification.new do |spec|
  spec.name          = "rails_console_pro"
  spec.version       = RailsConsolePro::VERSION
  spec.authors       = ["Harsh"]
  spec.email         = ["harsh.patel.hp846@gmail.com"]

  spec.summary       = "Enhanced Rails console with schema inspection, SQL explain, association navigation, and beautiful formatting"
  spec.description   = <<~DESC
    Rails Console Pro enhances your Rails console with powerful debugging tools:
    - Beautiful colored formatting for ActiveRecord objects
    - Schema inspection with columns, indexes, associations, validations
    - SQL explain analysis with performance recommendations
    - Interactive association navigation
    - Model statistics (record counts, growth rates, table sizes)
    - Object diffing and comparison
    - Export to JSON, YAML, and HTML
    - Smart pagination for large collections
  DESC
  spec.homepage      = "https://github.com/yourusername/rails_console_pro"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/yourusername/rails_console_pro"
  spec.metadata["changelog_uri"] = "https://github.com/yourusername/rails_console_pro/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  rescue
    # Fallback if git is not available
    Dir.glob("{lib,exe}/**/*", File::FNM_DOTMATCH).select { |f| File.file?(f) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "pastel", "~> 0.8.0"
  spec.add_dependency "tty-color", "~> 0.6.0"
  spec.add_dependency "pry", ">= 0.14.0", "< 0.16.0"
  spec.add_dependency "pry-rails", ">= 0.3.9"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rails", ">= 6.0"
  spec.add_development_dependency "sqlite3", "~> 2.1"
end

