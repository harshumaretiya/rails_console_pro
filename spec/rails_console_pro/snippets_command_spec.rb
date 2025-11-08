# frozen_string_literal: true

require 'rails_helper'
require_relative 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe RailsConsolePro::Commands::SnippetsCommand, type: :rails_console_pro do
  let(:store_dir) { Dir.mktmpdir('rails_console_pro_snippets') }
  let(:store_path) { File.join(store_dir, 'snippets.yml') }
  let(:command) { described_class.new }

  before do
    RailsConsolePro.configure do |config|
      config.snippets_command_enabled = true
      config.snippet_store_path = store_path
    end
  end

  after do
    FileUtils.rm_rf(store_dir)
  end

  describe '#execute' do
    it 'lists snippets with default limit' do
      command.execute(:add, "User.count", description: "Count users")
      result = command.execute(:list)

      expect(result).to be_a(RailsConsolePro::Snippets::CollectionResult)
      expect(result.size).to eq(1)
      expect(result.snippets.first.id).to include('count-users')
    end

    it 'adds snippet from block' do
      result = command.execute(:add, tags: %w[users]) do
        "User.where(active: true).count"
      end

      expect(result).to be_a(RailsConsolePro::Snippets::SingleResult)
      expect(result.created?).to be true
      expect(result.snippet.tags).to include('users')
      expect(result.snippet.body).to include('active')
    end

    it 'searches snippets by term and tags' do
      command.execute(:add, "User.count", tags: %w[metrics], description: "Count users")
      command.execute(:add, "Order.count", tags: %w[metrics])

      result = command.execute(:search, 'order', tags: %w[metrics])

      expect(result.snippets.count).to eq(1)
      expect(result.snippets.first.body).to include('Order.count')
    end

    it 'marks and unmarks favorites' do
      added = command.execute(:add, "User.count", id: "user-count")
      expect(added.snippet.favorite?).to be false

      favorite_result = command.execute(:favorite, 'user-count')
      expect(favorite_result.snippet.favorite?).to be true

      unfavorite_result = command.execute(:unfavorite, 'user-count')
      expect(unfavorite_result.snippet.favorite?).to be false
    end

    it 'removes snippet' do
      command.execute(:add, "User.count", id: "user-count")
      output = command.execute(:delete, 'user-count')
      expect(output).to include('Removed snippet')
      collection = command.execute(:list)
      expect(collection.size).to eq(0)
    end
  end

  describe 'when disabled' do
    before do
      RailsConsolePro.configure do |config|
        config.snippets_command_enabled = false
        config.snippet_store_path = store_path
      end
    end

    it 'returns disabled message' do
      message = command.execute(:list)
      expect(message).to include('Snippets command is disabled')
    end
  end
end


