module ActiveList
  module Definition
    class AttributeColumn < DataColumn
      attr_reader :column, :label_method, :sort_column, :computation_method

      def initialize(table, name, options = {})
        super(table, name, options)
        @label_method = (options[:label_method] || @name).to_sym
        unless @sort_column = options[:sort]
          @sort_column = if @table.model.columns_hash[@label_method.to_s]
                           @label_method
                         elsif @table.model.columns_hash[@name.to_s]
                           @name
                         end
        end
        @computation_method = options[:on_select]
        @column = @table.model.columns_hash[@label_method.to_s]
      end

      # Code for rows
      def datum_code(record = 'record_of_the_death', child = false)
        code = ''
        code = if child
                 if @options[:children].is_a?(FalseClass)
                   'nil'
                 else
                   "#{record}.#{table.options[:children]}.#{@options[:children] || @label_method}"
                        end
               else
                 "#{record}.#{@label_method}"
               end
        code.c
      end

      # Returns the class name of the used model
      def class_name
        table.model.name
      end

      def sortable?
        !sort_column.nil?
      end

      def computable?
        !computation_method.nil?
      end

      def enumerize?
        table.model.respond_to?(:enumerized_attributes) &&
          !table.model.enumerized_attributes[@label_method].nil?
      end

      def sort_expression
        "#{@table.model.table_name}.#{@sort_column}"
      end
    end
  end
end
