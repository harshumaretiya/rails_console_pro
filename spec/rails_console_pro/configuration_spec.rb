# frozen_string_literal: true

require 'rails_helper'
require_relative 'spec_helper'

RSpec.describe RailsConsolePro::Configuration, type: :rails_console_pro do
  let(:config) { described_class.new }

  describe '#initialize' do
    it 'sets default feature toggles' do
      expect(config.enabled).to be true
      expect(config.schema_command_enabled).to be true
      expect(config.stats_command_enabled).to be true
      expect(config.diff_command_enabled).to be true
      expect(config.export_enabled).to be true
    end

    it 'sets default color scheme' do
      expect(config.color_scheme).to eq(:dark)
    end

    it 'sets default style options' do
      expect(config.max_depth).to eq(10)
      expect(config.header_width).to eq(60)
      expect(config.border_char).to eq('─')
    end

    it 'sets default type colors' do
      expect(config.type_colors).to be_a(Hash)
      expect(config.type_colors[:integer]).to eq(:bright_blue)
      expect(config.type_colors[:string]).to eq(:green)
    end

    it 'sets default validator colors' do
      expect(config.validator_colors).to be_a(Hash)
      expect(config.validator_colors['PresenceValidator']).to eq(:red)
    end
  end

  describe '#color_scheme=' do
    it 'sets color scheme to dark' do
      config.color_scheme = :dark
      expect(config.color_scheme).to eq(:dark)
      expect(config.colors[:header]).to eq(:bright_blue)
    end

    it 'sets color scheme to light' do
      config.color_scheme = :light
      expect(config.color_scheme).to eq(:light)
      expect(config.colors[:header]).to eq(:bright_cyan)
    end

    it 'allows custom color scheme' do
      config.color_scheme = :custom
      expect(config.color_scheme).to eq(:custom)
    end
  end

  describe '#set_color' do
    it 'sets a custom color' do
      config.set_color(:header, :red)
      expect(config.get_color(:header)).to eq(:red)
      expect(config.color_scheme).to eq(:custom)
    end

    it 'updates existing color' do
      original = config.get_color(:header)
      config.set_color(:header, :green)
      expect(config.get_color(:header)).to eq(:green)
      expect(config.get_color(:header)).not_to eq(original)
    end
  end

  describe '#get_color' do
    it 'returns color value' do
      expect(config.get_color(:header)).to eq(:bright_blue)
    end

    it 'returns :white for unknown color' do
      expect(config.get_color(:nonexistent)).to eq(:white)
    end
  end

  describe '#set_type_color' do
    it 'sets type color' do
      config.set_type_color(:integer, :red)
      expect(config.get_type_color(:integer)).to eq(:red)
    end

    it 'updates existing type color' do
      config.set_type_color(:string, :yellow)
      expect(config.get_type_color(:string)).to eq(:yellow)
    end
  end

  describe '#get_type_color' do
    it 'returns type color' do
      expect(config.get_type_color(:integer)).to eq(:bright_blue)
    end

    it 'returns :white for unknown type' do
      expect(config.get_type_color(:nonexistent)).to eq(:white)
    end
  end

  describe '#set_validator_color' do
    it 'sets validator color' do
      config.set_validator_color('PresenceValidator', :blue)
      expect(config.get_validator_color('PresenceValidator')).to eq(:blue)
    end
  end

  describe '#get_validator_color' do
    it 'returns validator color' do
      expect(config.get_validator_color('PresenceValidator')).to eq(:red)
    end

    it 'returns :white for unknown validator' do
      expect(config.get_validator_color('NonexistentValidator')).to eq(:white)
    end
  end

  describe '#disable_all' do
    it 'disables all features' do
      config.disable_all
      expect(config.enabled).to be false
      expect(config.schema_command_enabled).to be false
      expect(config.stats_command_enabled).to be false
      expect(config.diff_command_enabled).to be false
      expect(config.export_enabled).to be false
    end
  end

  describe '#enable_all' do
    it 'enables all features' do
      config.disable_all
      config.enable_all
      expect(config.enabled).to be true
      expect(config.schema_command_enabled).to be true
      expect(config.stats_command_enabled).to be true
      expect(config.diff_command_enabled).to be true
      expect(config.export_enabled).to be true
    end
  end

  describe '#reset' do
    it 'resets to defaults' do
      config.set_color(:header, :red)
      config.disable_all
      config.reset
      expect(config.get_color(:header)).to eq(:bright_blue)
      expect(config.enabled).to be true
    end
  end

  describe 'feature toggles' do
    it 'allows toggling individual features' do
      config.schema_command_enabled = false
      expect(config.schema_command_enabled).to be false
      expect(config.stats_command_enabled).to be true
    end
  end
end

