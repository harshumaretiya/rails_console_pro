# frozen_string_literal: true

require 'json'
require 'yaml'

module RailsConsolePro
  # Format exporter for converting data to JSON, YAML, and HTML
  module FormatExporter
    extend self

    # Export to JSON format
    # Similar to awesome_print philosophy: convert objects to JSON-serializable structures
    # Supports both pretty-printed and compact formats
    def to_json(data, pretty: true, options: {})
      json_data = serialize_data(data)
      
      # Apply awesome_print-style options if provided
      if pretty
        # Ruby's JSON.pretty_generate uses 2-space indentation by default
        JSON.pretty_generate(json_data)
      else
        JSON.generate(json_data)
      end
    rescue JSON::GeneratorError => e
      # Fallback for complex objects that can't be serialized
      { error: "Could not serialize to JSON", message: e.message, type: data.class.name }.to_json
    end

    # Export to YAML format
    def to_yaml(data)
      yaml_data = serialize_data(data)
      # Convert symbols to strings for YAML.safe_load compatibility
      yaml_data = convert_symbols_to_strings(yaml_data)
      yaml_data.to_yaml
    end

    # Export to HTML format
    def to_html(data, title: nil, style: :default)
      html_data = serialize_data(data)
      generate_html(html_data, title: title || infer_title(data), style: style)
    end

    # Export to file
    def export_to_file(data, file_path, format: nil)
      return nil if data.nil?
      
      format ||= infer_format_from_path(file_path)
      content = case format.to_s.downcase
                when 'json'
                  to_json(data)
                when 'yaml', 'yml'
                  to_yaml(data)
                when 'html', 'htm'
                  to_html(data, title: infer_title(data))
                else
                  raise ArgumentError, "Unsupported format: #{format}. Supported: json, yaml, html"
                end

      File.write(file_path, content)
      file_path
    rescue ArgumentError, Errno::ENOENT, Errno::EACCES, Errno::ENOSPC => e
      # Handle file system errors gracefully
      nil
    rescue => e
      # Handle any other errors
      nil
    end

    private

    # Serialize data to a hash structure
    # Similar to awesome_print's approach: handle native types directly,
    # convert complex objects to structured data
    def serialize_data(data)
      case data
      when SchemaInspectorResult
        serialize_schema_result(data)
      when StatsResult
        serialize_stats_result(data)
      when DiffResult
        serialize_diff_result(data)
      when ExplainResult
        serialize_explain_result(data)
      when ActiveRecord::Base
        serialize_active_record(data)
      when ActiveRecord::Relation
        serialize_relation(data)
      when Array
        serialize_array(data)
      when Hash
        # Recursively serialize hash values (awesome_print-style)
        serialize_hash(data)
      when String, Numeric, TrueClass, FalseClass, NilClass
        # Native JSON types - return as-is
        data
      when Symbol
        # Convert symbols to strings for JSON/YAML compatibility
        data.to_s
      when Regexp
        # Convert regexp to string for JSON/YAML compatibility
        data.to_s
      when Time, Date, DateTime, ActiveSupport::TimeWithZone
        # Convert time objects to ISO8601 strings (JSON-friendly)
        data.iso8601
      else
        # Fallback: try to_json if available, otherwise use inspect
        if data.respond_to?(:to_json)
          JSON.parse(data.to_json)
        elsif data.respond_to?(:attributes)
          # Object with attributes (like ActiveRecord but not ActiveRecord::Base)
          serialize_object_with_attributes(data)
        else
          { type: data.class.name, value: data.inspect }
        end
      end
    end

    def serialize_schema_result(result)
      model = result.model
      {
        'type' => 'schema_inspection',
        'model' => model.name,
        'table_name' => model.table_name,
        'columns' => serialize_columns(model),
        'indexes' => serialize_indexes(model),
        'associations' => serialize_associations(model),
        'validations' => serialize_validations(model),
        'scopes' => serialize_scopes(model),
        'database' => serialize_database_info(model)
      }
    end

    def serialize_explain_result(result)
      {
        'type' => 'sql_explain',
        'sql' => result.sql,
        'execution_time' => result.execution_time,
        'explain_output' => format_explain_output(result.explain_output),
        'indexes_used' => result.indexes_used,
        'recommendations' => result.recommendations,
        'statistics' => result.statistics,
        'slow_query' => result.slow_query?,
        'has_indexes' => result.has_indexes?
      }
    end

    def serialize_stats_result(result)
      {
        'type' => 'statistics',
        'model' => result.model.name,
        'record_count' => result.record_count,
        'growth_rate' => result.growth_rate,
        'table_size' => result.table_size,
        'index_usage' => serialize_data(result.index_usage),
        'column_stats' => serialize_data(result.column_stats),
        'timestamp' => result.timestamp.iso8601,
        'has_growth_data' => result.has_growth_data?,
        'has_table_size' => result.has_table_size?,
        'has_index_data' => result.has_index_data?
      }
    end

    def serialize_diff_result(result)
      {
        'type' => 'diff_comparison',
        'object1_type' => result.object1_type,
        'object2_type' => result.object2_type,
        'identical' => result.identical,
        'different_types' => result.different_types?,
        'diff_count' => result.diff_count,
        'has_differences' => result.has_differences?,
        'differences' => serialize_data(result.differences),
        'object1' => serialize_data(result.object1),
        'object2' => serialize_data(result.object2),
        'timestamp' => result.timestamp.iso8601
      }
    end

    def serialize_active_record(record)
      {
        'type' => 'active_record',
        'class' => record.class.name,
        'id' => record.id,
        'attributes' => record.attributes,
        'errors' => record.errors.any? ? record.errors.full_messages : nil
      }.compact
    end

    def serialize_relation(relation)
      records = relation.to_a
      {
        'type' => 'active_record_relation',
        'model' => relation.klass.name,
        'count' => records.size,
        'records' => records.map { |r| serialize_active_record(r) },
        'sql' => relation.to_sql
      }
    end

    def serialize_array(array)
      if array.all? { |item| item.is_a?(ActiveRecord::Base) }
        {
          'type' => 'active_record_collection',
          'model' => array.first.class.name,
          'count' => array.size,
          'records' => array.map { |r| serialize_active_record(r) }
        }
      else
        {
          'type' => 'array',
          'count' => array.size,
          'items' => array.map { |item| serialize_data(item) }
        }
      end
    end

    def serialize_hash(hash)
      # Recursively serialize hash values (awesome_print-style deep conversion)
      # Convert symbol keys to strings for YAML compatibility
      hash.each_with_object({}) do |(key, value), result|
        string_key = key.is_a?(Symbol) ? key.to_s : key
        result[string_key] = serialize_data(value)
      end
    end

    def serialize_object_with_attributes(obj)
      # Handle objects with attributes method (similar to awesome_print's approach)
      attrs = obj.attributes rescue {}
      {
        _type: obj.class.name,
        **attrs.transform_values { |v| serialize_data(v) }
      }
    end

    def serialize_columns(model)
      model.columns.map do |column|
        {
          'name' => column.name.to_s,
          'type' => column.type.to_s,
          'null' => column.null,
          'default' => column.default,
          'limit' => column.limit,
          'precision' => column.precision,
          'scale' => column.scale
        }.compact
      end
    end

    def serialize_indexes(model)
      model.connection.indexes(model.table_name).map do |index|
        where_clause = if index.where.is_a?(Regexp)
                         index.where.to_s
                       else
                         index.where
                       end
        {
          'name' => index.name.to_s,
          'columns' => index.columns.map(&:to_s),
          'unique' => index.unique,
          'where' => where_clause
        }.compact
      end
    end

    def serialize_associations(model)
      associations = {}
      %i[belongs_to has_one has_many has_and_belongs_to_many].each do |macro|
        assocs = model.reflect_on_all_associations(macro)
        next if assocs.empty?

        associations[macro.to_s] = assocs.map do |assoc|
          {
            'name' => assoc.name.to_s,
            'class_name' => assoc.class_name,
            'foreign_key' => assoc.respond_to?(:foreign_key) ? assoc.foreign_key : nil,
            'dependent' => assoc.options[:dependent]&.to_s,
            'optional' => assoc.options[:optional],
            'through' => assoc.options[:through]&.to_s,
            'join_table' => assoc.respond_to?(:join_table) ? assoc.join_table : nil
          }.compact
        end
      end
      associations
    end

    def serialize_validations(model)
      validators_by_attr = model.validators.each_with_object({}) do |validator, hash|
        validator.attributes.each do |attr|
          attr_key = attr.is_a?(Symbol) ? attr.to_s : attr
          (hash[attr_key] ||= []) << {
            type: validator.class.name.split('::').last.gsub('Validator', ''),
            options: serialize_options(validator.options)
          }
        end
      end
      validators_by_attr
    end

    def serialize_options(options)
      return nil if options.nil?
      return options if options.empty?
      
      options.each_with_object({}) do |(key, value), result|
        string_key = key.is_a?(Symbol) ? key.to_s : key
        result[string_key] = case value
        when Symbol
          value.to_s
        when Regexp
          value.to_s
        when Array
          value.map { |v| v.is_a?(Symbol) || v.is_a?(Regexp) ? v.to_s : serialize_data(v) }
        else
          serialize_data(value)
        end
      end
    end

    def serialize_scopes(model)
      return [] unless model.respond_to?(:scopes) && model.scopes.any?

      model.scopes.keys.map(&:to_s)
    end

    def serialize_database_info(model)
      connection = model.connection
      {
        adapter: connection.adapter_name,
        database: connection.respond_to?(:current_database) ? connection.current_database : nil
      }.compact
    end

    def format_explain_output(explain_output)
      case explain_output
      when String
        explain_output
      when Array
        explain_output.map { |row| row.is_a?(Hash) ? row : row.to_s }
      else
        explain_output.inspect
      end
    end

    def generate_html(data, title:, style:)
      html_title = escape_html(title)
      html_content = generate_html_content(data)
      css = generate_css(style)

      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>#{html_title}</title>
          <style>#{css}</style>
        </head>
        <body>
          <div class="container">
            <h1 class="title">#{html_title}</h1>
            <div class="content">
              #{html_content}
            </div>
            <div class="footer">
              <p>Generated by Enhanced Console Printer at #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}</p>
            </div>
          </div>
        </body>
        </html>
      HTML
    end

    def generate_html_content(data, depth: 0)
      case data
      when Hash
        generate_hash_html(data, depth)
      when Array
        generate_array_html(data, depth)
      when String, Numeric, TrueClass, FalseClass, NilClass
        generate_value_html(data)
      else
        generate_value_html(data.inspect)
      end
    end

    def generate_hash_html(hash, depth)
      return '<span class="empty">Empty hash</span>' if hash.empty?

      html = '<dl class="hash">'
      hash.each do |key, value|
        key_class = value.is_a?(Hash) || value.is_a?(Array) ? 'key-expandable' : 'key'
        html += "<dt class=\"#{key_class}\">#{escape_html(key.to_s)}</dt>"
        html += "<dd class=\"value\">#{generate_html_content(value, depth: depth + 1)}</dd>"
      end
      html + '</dl>'
    end

    def generate_array_html(array, depth)
      return '<span class="empty">Empty array</span>' if array.empty?

      html = '<ul class="array">'
      array.each do |item|
        html += "<li>#{generate_html_content(item, depth: depth + 1)}</li>"
      end
      html + '</ul>'
    end

    def generate_value_html(value)
      case value
      when NilClass
        '<span class="nil">nil</span>'
      when TrueClass
        '<span class="boolean true">true</span>'
      when FalseClass
        '<span class="boolean false">false</span>'
      when Numeric
        "<span class=\"number\">#{escape_html(value.to_s)}</span>"
      when String
        "<span class=\"string\">#{escape_html(value)}</span>"
      else
        "<span class=\"other\">#{escape_html(value.inspect)}</span>"
      end
    end

    def generate_css(style)
      case style
      when :default
        default_css
      when :minimal
        minimal_css
      else
        default_css
      end
    end

    def default_css
      <<~CSS
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
          line-height: 1.6;
          color: #333;
          background: #f5f5f5;
          padding: 20px;
        }
        .container {
          max-width: 1200px;
          margin: 0 auto;
          background: white;
          border-radius: 8px;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
          padding: 30px;
        }
        .title {
          color: #2c3e50;
          border-bottom: 3px solid #3498db;
          padding-bottom: 10px;
          margin-bottom: 20px;
        }
        .content {
          margin-bottom: 30px;
        }
        dl.hash {
          margin: 10px 0;
        }
        dt.key, dt.key-expandable {
          font-weight: bold;
          color: #2980b9;
          margin-top: 10px;
          margin-bottom: 5px;
        }
        dt.key-expandable {
          cursor: pointer;
          user-select: none;
        }
        dt.key-expandable:hover {
          color: #1f5f8b;
        }
        dd.value {
          margin-left: 20px;
          margin-bottom: 10px;
        }
        ul.array {
          margin-left: 20px;
          list-style-type: disc;
        }
        ul.array li {
          margin: 5px 0;
        }
        .nil { color: #95a5a6; font-style: italic; }
        .boolean.true { color: #27ae60; font-weight: bold; }
        .boolean.false { color: #e74c3c; font-weight: bold; }
        .number { color: #3498db; font-weight: bold; }
        .string { color: #2ecc71; }
        .other { color: #7f8c8d; }
        .empty { color: #95a5a6; font-style: italic; }
        .footer {
          margin-top: 30px;
          padding-top: 20px;
          border-top: 1px solid #ecf0f1;
          text-align: center;
          color: #95a5a6;
          font-size: 0.9em;
        }
        @media print {
          body { background: white; padding: 0; }
          .container { box-shadow: none; }
        }
      CSS
    end

    def minimal_css
      <<~CSS
        body { font-family: monospace; padding: 20px; }
        .container { max-width: 800px; margin: 0 auto; }
        .title { border-bottom: 1px solid #ccc; padding-bottom: 10px; }
        dt { font-weight: bold; margin-top: 10px; }
        dd { margin-left: 20px; }
        ul { margin-left: 20px; }
        .nil { color: #999; }
        .boolean.true { color: green; }
        .boolean.false { color: red; }
        .number { color: blue; }
        .string { color: #333; }
      CSS
    end

    def escape_html(text)
      text.to_s
          .gsub('&', '&amp;')
          .gsub('<', '&lt;')
          .gsub('>', '&gt;')
          .gsub('"', '&quot;')
          .gsub("'", '&#39;')
    end

    # Convert all symbols in data structure to strings for YAML.safe_load compatibility
    def convert_symbols_to_strings(data)
      case data
      when Hash
        data.each_with_object({}) do |(key, value), result|
          string_key = key.is_a?(Symbol) ? key.to_s : key
          result[string_key] = convert_symbols_to_strings(value)
        end
      when Array
        data.map { |item| convert_symbols_to_strings(item) }
      when Symbol
        data.to_s
      else
        data
      end
    end

    def infer_format_from_path(path)
      ext = File.extname(path).downcase.delete('.')
      return 'json' if ext.empty? # Default to JSON if no extension
      ext
    end

    def infer_title(data)
      case data
      when SchemaInspectorResult
        "Schema: #{data.model.name}"
      when StatsResult
        "Statistics: #{data.model.name}"
      when DiffResult
        "Diff Comparison: #{data.object1_type} vs #{data.object2_type}"
      when ExplainResult
        "SQL Explain Analysis"
      when ActiveRecord::Base
        "#{data.class.name} ##{data.id}"
      when ActiveRecord::Relation
        "#{data.klass.name} Collection (#{data.count} records)"
      when Array
        data.first.is_a?(ActiveRecord::Base) ? "#{data.first.class.name} Collection (#{data.size} records)" : "Array (#{data.size} items)"
      else
        "Export"
      end
    end
  end
end

