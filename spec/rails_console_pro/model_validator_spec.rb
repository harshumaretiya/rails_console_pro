# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RailsConsolePro::ModelValidator, type: :rails_console_pro do
  describe '.valid_model?' do
    context 'with valid ActiveRecord model' do
      it 'returns true for User model' do
        expect(described_class.valid_model?(User)).to be true
      end

      it 'returns true for Character model' do
        expect(described_class.valid_model?(Character)).to be true
      end
    end

    context 'with invalid inputs' do
      it 'returns false for String' do
        expect(described_class.valid_model?('User')).to be false
      end

      it 'returns false for nil' do
        expect(described_class.valid_model?(nil)).to be false
      end

      it 'returns false for non-ActiveRecord class' do
        expect(described_class.valid_model?(String)).to be false
      end

      it 'returns false for instance' do
        expect(described_class.valid_model?(User.new)).to be false
      end
    end
  end

  describe '.has_table?' do
    context 'with model that has table' do
      it 'returns true for User' do
        expect(described_class.has_table?(User)).to be true
      end

      it 'returns true for Character' do
        expect(described_class.has_table?(Character)).to be true
      end
    end

    context 'with abstract class' do
      let(:abstract_class) do
        Class.new(ActiveRecord::Base) do
          self.abstract_class = true
        end
      end

      it 'returns false' do
        expect(described_class.has_table?(abstract_class)).to be false
      end
    end

    context 'with invalid model' do
      it 'returns false for String' do
        expect(described_class.has_table?(String)).to be false
      end
    end
  end

  describe '.abstract_class?' do
    context 'with abstract class' do
      let(:abstract_class) do
        Class.new(ActiveRecord::Base) do
          self.abstract_class = true
        end
      end

      it 'returns true' do
        expect(described_class.abstract_class?(abstract_class)).to be true
      end
    end

    context 'with concrete class' do
      it 'returns false for User' do
        expect(described_class.abstract_class?(User)).to be false
      end
    end

    context 'with invalid input' do
      it 'returns false for String' do
        expect(described_class.abstract_class?(String)).to be false
      end
    end
  end

  describe '.sti_model?' do
    context 'with STI model' do
      # Create a test STI model
      let(:sti_base) do
        Class.new(ActiveRecord::Base) do
          self.table_name = 'users'
          # STI uses type column
        end
      end

      let(:sti_child) do
        Class.new(sti_base) do
          # Child class
        end
      end

      it 'returns true if model has type column' do
        # Note: This test depends on actual STI setup
        # For User model, we'd need to check if it actually uses STI
        skip 'Requires actual STI setup in test database'
      end
    end

    context 'with non-STI model' do
      it 'returns false for User' do
        # Mock column_names to avoid database query
        allow(User).to receive(:column_names).and_return(['id', 'email', 'created_at', 'updated_at'])
        allow(User).to receive(:inheritance_column).and_return('type')
        # Assuming User doesn't use STI (no 'type' column)
        expect(described_class.sti_model?(User)).to be false
      end
    end

    context 'with abstract class' do
      let(:abstract_class) do
        Class.new(ActiveRecord::Base) do
          self.abstract_class = true
        end
      end

      it 'returns false' do
        expect(described_class.sti_model?(abstract_class)).to be false
      end
    end
  end

  describe '.has_timestamp_column?' do
    context 'with model that has created_at' do
      it 'returns true for User' do
        allow(User).to receive(:column_names).and_return(['id', 'email', 'created_at', 'updated_at'])
        expect(described_class.has_timestamp_column?(User)).to be true
      end

      it 'returns true for Character' do
        allow(Character).to receive(:column_names).and_return(['id', 'name', 'created_at', 'updated_at'])
        expect(described_class.has_timestamp_column?(Character)).to be true
      end
    end

    context 'with custom column name' do
      it 'checks for specified column' do
        allow(User).to receive(:column_names).and_return(['id', 'email', 'created_at', 'updated_at'])
        # Assuming User has updated_at
        expect(described_class.has_timestamp_column?(User, 'updated_at')).to be true
      end
    end

    context 'with invalid model' do
      it 'returns false for String' do
        expect(described_class.has_timestamp_column?(String)).to be false
      end
    end

    context 'with abstract class' do
      let(:abstract_class) do
        Class.new(ActiveRecord::Base) do
          self.abstract_class = true
        end
      end

      it 'returns false' do
        expect(described_class.has_timestamp_column?(abstract_class)).to be false
      end
    end
  end

  describe '.large_table?' do
    context 'with small table' do
      before do
        # Mock count for small table
        allow(User).to receive(:count).and_return(2)
      end

      it 'returns false for small table' do
        expect(described_class.large_table?(User, threshold: 10)).to be false
      end
    end

    context 'with custom threshold' do
      it 'uses custom threshold' do
        expect(described_class.large_table?(User, threshold: 1_000_000)).to be false
      end
    end

    context 'with invalid model' do
      it 'returns false for String' do
        expect(described_class.large_table?(String)).to be false
      end
    end
  end

  describe '.model_info' do
    it 'returns hash with model information' do
      info = described_class.model_info(User)
      
      expect(info).to be_a(Hash)
      expect(info).to have_key(:valid)
      expect(info).to have_key(:has_table)
      expect(info).to have_key(:abstract)
      expect(info).to have_key(:sti)
      expect(info).to have_key(:has_created_at)
      expect(info).to have_key(:large)
    end

    it 'returns correct values for User' do
      info = described_class.model_info(User)
      
      expect(info[:valid]).to be true
      expect(info[:has_table]).to be true
      expect(info[:abstract]).to be false
      expect(info[:has_created_at]).to be true
    end
  end

  describe '.validate_for_schema' do
    context 'with valid model' do
      it 'returns nil' do
        expect(described_class.validate_for_schema(User)).to be_nil
      end
    end

    context 'with invalid model' do
      it 'returns error message for String' do
        expect(described_class.validate_for_schema(String)).to eq('Not an ActiveRecord model')
      end
    end

    context 'with abstract class' do
      let(:abstract_class) do
        Class.new(ActiveRecord::Base) do
          self.abstract_class = true
        end
      end

      it 'returns error message' do
        expect(described_class.validate_for_schema(abstract_class)).to eq('Abstract class - no database table')
      end
    end
  end

  describe '.validate_for_stats' do
    context 'with valid model' do
      it 'returns nil' do
        expect(described_class.validate_for_stats(User)).to be_nil
      end
    end

    context 'with invalid model' do
      it 'returns error message' do
        expect(described_class.validate_for_stats(String)).to eq('Not an ActiveRecord model')
      end
    end
  end

  describe '.valid_associations?' do
    context 'with valid association' do
      it 'returns true for has_many association' do
        # Assuming User has_many :conversations
        if User.reflect_on_association(:conversations)
          expect(described_class.valid_associations?(User, :conversations)).to be true
        end
      end
    end

    context 'with invalid association' do
      it 'returns false for non-existent association' do
        expect(described_class.valid_associations?(User, :nonexistent)).to be false
      end
    end

    context 'with invalid model' do
      it 'returns false' do
        expect(described_class.valid_associations?(String, :anything)).to be false
      end
    end
  end

  describe '.safe_table_name' do
    context 'with valid model' do
      it 'returns table name' do
        expect(described_class.safe_table_name(User)).to eq('users')
      end
    end

    context 'with invalid model' do
      it 'returns nil' do
        expect(described_class.safe_table_name(String)).to be_nil
      end
    end
  end

  describe '.safe_column_names' do
    context 'with valid model' do
      before do
        # Mock columns to avoid database queries
        mock_columns = [
          double('Column', name: 'id'),
          double('Column', name: 'email'),
          double('Column', name: 'created_at')
        ]
        allow(User).to receive(:columns).and_return(mock_columns)
      end

      it 'returns array of column names' do
        names = described_class.safe_column_names(User)
        expect(names).to be_an(Array)
        expect(names).to include('id', 'email', 'created_at')
      end
    end

    context 'with abstract class' do
      let(:abstract_class) do
        Class.new(ActiveRecord::Base) do
          self.abstract_class = true
        end
      end

      it 'returns empty array' do
        expect(described_class.safe_column_names(abstract_class)).to eq([])
      end
    end
  end

  describe '.safe_columns' do
    context 'with valid model' do
      before do
        # Mock columns to avoid database queries
        mock_columns = [
          double('Column', name: 'id', type: :integer),
          double('Column', name: 'email', type: :string)
        ]
        allow(User).to receive(:columns).and_return(mock_columns)
      end

      it 'returns array of column objects' do
        columns = described_class.safe_columns(User)
        expect(columns).to be_an(Array)
        expect(columns.first).to respond_to(:name)
        expect(columns.first).to respond_to(:type)
      end
    end

    context 'with abstract class' do
      let(:abstract_class) do
        Class.new(ActiveRecord::Base) do
          self.abstract_class = true
        end
      end

      it 'returns empty array' do
        expect(described_class.safe_columns(abstract_class)).to eq([])
      end
    end
  end

  describe '.safe_indexes' do
    context 'with valid model' do
      it 'returns array of indexes' do
        indexes = described_class.safe_indexes(User)
        expect(indexes).to be_an(Array)
      end
    end

    context 'with abstract class' do
      let(:abstract_class) do
        Class.new(ActiveRecord::Base) do
          self.abstract_class = true
        end
      end

      it 'returns empty array' do
        expect(described_class.safe_indexes(abstract_class)).to eq([])
      end
    end
  end

  describe '.safe_associations' do
    context 'with valid model' do
      it 'returns array of associations' do
        associations = described_class.safe_associations(User)
        expect(associations).to be_an(Array)
      end

      it 'filters by macro when specified' do
        belongs_to_assocs = described_class.safe_associations(User, :belongs_to)
        expect(belongs_to_assocs).to be_an(Array)
        belongs_to_assocs.each do |assoc|
          expect(assoc.macro).to eq(:belongs_to)
        end
      end
    end

    context 'with invalid model' do
      it 'returns empty array' do
        expect(described_class.safe_associations(String)).to eq([])
      end
    end
  end

  describe '.unusual_inheritance?' do
    context 'with normal inheritance' do
      it 'returns false for User' do
        expect(described_class.unusual_inheritance?(User)).to be false
      end
    end

    context 'with invalid model' do
      it 'returns false for String' do
        expect(described_class.unusual_inheritance?(String)).to be false
      end
    end
  end
end

