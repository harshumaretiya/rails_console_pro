# frozen_string_literal: true

module RailsConsolePro
  # Smart paginator for large collections with lazy enumeration
  # Uses advanced Ruby concepts: Enumerator, lazy evaluation, and interactive I/O
  class Paginator
    include ColorHelper

    # Navigation commands
    COMMANDS = {
      next: ['n', 'next', ''],
      previous: ['p', 'prev', 'previous'],
      first: ['f', 'first'],
      last: ['l', 'last'],
      jump: ['j', 'jump', 'goto', 'g'],
      quit: ['q', 'quit', 'exit']
    }.freeze

    def initialize(output, collection, total_count, config, record_printer_proc)
      @output = output
      @collection = collection
      @total_count = total_count
      @config = config
      @record_printer_proc = record_printer_proc
      @page_size = config.pagination_page_size
      @current_page = 1
      @total_pages = calculate_total_pages
    end

    # Start paginated display
    def paginate
      return print_all if @total_count <= @config.pagination_threshold || !@config.pagination_enabled

      loop do
        print_page
        command = get_user_command
        break if command == :quit

        handle_command(command)
      end
    end

    private

    def calculate_total_pages
      (@total_count.to_f / @page_size).ceil
    end

    def print_all
      # For small collections, print everything without pagination
      @collection.each_with_index do |record, index|
        print_record(record, index)
      end
    end

    def print_page
      clear_screen_info
      print_header
      
      records = page_records
      records.each_with_index do |record, index|
        global_index = page_start_index + index
        print_record(record, global_index)
      end
      
      print_footer
      print_pagination_controls
    end

    def page_records
      # Use lazy enumeration to avoid loading unnecessary records
      start_index = page_start_index
      
      if @collection.is_a?(ActiveRecord::Relation)
        # For Relations, use offset/limit for efficient database queries
        @collection.offset(start_index).limit(@page_size).to_a
      elsif @collection.respond_to?(:to_ary)
        # For arrays, use slice for better performance (O(1) with range)
        @collection[start_index, @page_size] || []
      elsif @collection.respond_to?(:each)
        # For other enumerables, use lazy enumeration
        @collection.lazy.drop(start_index).take(@page_size).to_a
      else
        []
      end
    end

    def page_start_index
      (@current_page - 1) * @page_size
    end

    def page_end_index
      [page_start_index + @page_size - 1, @total_count - 1].min
    end

    def print_record(record, index)
      @output.puts color(@config.get_color(:info), "[#{index}]")
      @record_printer_proc.call(record)
    end

    def print_header
      model_name = extract_model_name
      showing = "#{page_start_index + 1}-#{page_end_index + 1}"
      header = "#{model_name} Collection (Showing #{showing} of #{@total_count} records)"
      @output.puts color(@config.get_color(:success), header)
      @output.puts
    end

    def print_footer
      @output.puts
    end

    def print_pagination_controls
      page_info = color(@config.get_color(:info), "Page #{@current_page}/#{@total_pages}")
      controls = "Commands: " + 
                color(:dim, "[n]ext") + " " +
                color(:dim, "[p]rev") + " " +
                color(:dim, "[f]irst") + " " +
                color(:dim, "[l]ast") + " " +
                color(:dim, "[j]ump") + " " +
                color(:dim, "[#]page") + " " +
                color(:dim, "[q]uit")
      
      @output.puts page_info
      @output.puts controls
      @output.puts
    end

    def extract_model_name
      if @collection.is_a?(ActiveRecord::Relation)
        @collection.klass.name
      elsif @collection.respond_to?(:to_ary) && !@collection.empty?
        # For arrays, safely check first element
        first_item = @collection[0]
        first_item.is_a?(ActiveRecord::Base) ? first_item.class.name : "Collection"
      else
        "Collection"
      end
    end

    def clear_screen_info
      # Clear previous pagination info (simple approach - just add spacing)
      @output.puts
    end

    def get_user_command
      @output.print color(@config.get_color(:success), "➤ Enter command: ")
      input = $stdin.gets&.chomp&.downcase&.strip || 'q'
      
      normalize_command(input)
    end

    def normalize_command(input)
      COMMANDS.each do |command, aliases|
        return command if aliases.include?(input)
      end
      
      # Check if it's a page number (direct jump)
      if input.match?(/^\d+$/)
        page_num = input.to_i
        if page_num.between?(1, @total_pages)
          @current_page = page_num
          return :page_changed
        else
          @output.puts color(@config.get_color(:error), "Invalid page number (1-#{@total_pages}). Staying on page #{@current_page}.")
          return :noop
        end
      end
      
      # Default to next if unrecognized
      :next
    end

    def handle_command(command)
      case command
      when :next
        @current_page = [@current_page + 1, @total_pages].min
      when :previous
        @current_page = [@current_page - 1, 1].max
      when :first
        @current_page = 1
      when :last
        @current_page = @total_pages
      when :jump
        jump_to_page
      when :page_changed, :noop
        # Already handled in normalize_command
      end
    end

    def jump_to_page
      @output.print color(@config.get_color(:success), "➤ Enter page number (1-#{@total_pages}): ")
      input = $stdin.gets&.chomp&.strip
      page_num = input.to_i
      
      if page_num.between?(1, @total_pages)
        @current_page = page_num
      else
        @output.puts color(@config.get_color(:error), "Invalid page number. Staying on page #{@current_page}.")
      end
    end
  end
end

