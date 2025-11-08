 # frozen_string_literal: true
 
 module RailsConsolePro
   # Value object representing a profiling session summary
   class ProfileResult
     QuerySample = Struct.new(
       :sql,
       :duration_ms,
       :cached,
       :name,
       :binds,
       keyword_init: true
     )

     DuplicateQuery = Struct.new(
       :fingerprint,
       :sql,
       :count,
       :total_duration_ms,
       keyword_init: true
     )

     attr_reader :label,
                 :duration_ms,
                 :result,
                 :error,
                 :query_count,
                 :cached_query_count,
                 :write_query_count,
                 :total_sql_duration_ms,
                 :slow_queries,
                 :duplicate_queries,
                 :query_samples,
                 :instantiation_count,
                 :cache_hits,
                 :cache_misses,
                 :cache_writes,
                 :started_at,
                 :finished_at

     def initialize(label:, duration_ms:, result:, error:, query_count:, cached_query_count:,
                    write_query_count:, total_sql_duration_ms:, slow_queries:, duplicate_queries:,
                    query_samples:, instantiation_count:, cache_hits:, cache_misses:,
                    cache_writes:, started_at:, finished_at:)
       @label = label
       @duration_ms = duration_ms
       @result = result
       @error = error
       @query_count = query_count
       @cached_query_count = cached_query_count
       @write_query_count = write_query_count
       @total_sql_duration_ms = total_sql_duration_ms
       @slow_queries = Array(slow_queries)
       @duplicate_queries = Array(duplicate_queries)
       @query_samples = Array(query_samples)
       @instantiation_count = instantiation_count
       @cache_hits = cache_hits
       @cache_misses = cache_misses
       @cache_writes = cache_writes
       @started_at = started_at
       @finished_at = finished_at
     end

    def label?
      !(label.nil? || (label.respond_to?(:empty?) && label.empty?))
     end

     def error?
       !error.nil?
     end

     def cache_activity?
       cache_hits.positive? || cache_misses.positive? || cache_writes.positive?
     end

     def slow_queries?
       slow_queries.any?
     end

     def duplicate_queries?
       duplicate_queries.any?
     end

     def query_samples?
       query_samples.any?
     end

     def read_query_count
       query_count - write_query_count
     end

     def to_json(pretty: true)
       FormatExporter.to_json(self, pretty: pretty)
     end

     def to_yaml
       FormatExporter.to_yaml(self)
     end

     def to_html(style: :default)
       FormatExporter.to_html(self, title: "Profile: #{label || 'Session'}", style: style)
     end

     def export_to_file(file_path, format: nil)
       FormatExporter.export_to_file(self, file_path, format: format)
     end
   end
 end

