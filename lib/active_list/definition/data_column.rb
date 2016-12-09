module ActiveList
  module Definition
    class DataColumn < AbstractColumn
      LABELS_COLUMNS = [:full_name, :label, :name, :number, :coordinate]

      def header_code
        if @options[:label]
          "#{@options[:label].to_s.strip.inspect}.t(scope: 'labels')".c
        else
          "#{@table.model.name}.human_attribute_name(#{@name.inspect})".c
        end
      end

      # Code for exportation
      def exporting_datum_code(record = 'record_of_the_death', noview = false)
        datum = datum_code(record)
        if datatype == :boolean
          datum = "(#{datum} ? ::I18n.translate('list.export.true_value') : ::I18n.translate('list.export.false_value'))"
        elsif datatype == :date
          datum = "(#{datum}.nil? ? '' : #{datum}.l)"
        elsif datatype == :decimal && !noview
          currency = nil
          if currency = options[:currency]
            currency = currency[:body] if currency.is_a?(Hash)
            currency = :currency if currency.is_a?(TrueClass)
            currency = "#{record}.#{currency}".c if currency.is_a?(Symbol)
          end
          datum = "(#{datum}.nil? ? '' : #{datum}.l(#{'currency: ' + currency.inspect if currency}))"
        elsif @name.to_s.match(/(^|\_)currency$/) && datatype == :string
          datum = "(Nomen::Currencies[#{datum}] ? Nomen::Currencies[#{datum}].human_name : '')"
        elsif @name.to_s.match(/(^|\_)country$/) && datatype == :string
          datum = "(Nomen::Countries[#{datum}] ? Nomen::Countries[#{datum}].human_name : '')"
        elsif @name.to_s.match(/(^|\_)language$/) && datatype == :string
          datum = "(Nomen::Languages[#{datum}] ? Nomen::Languages[#{datum}].human_name : '')"
        elsif self.enumerize?
          datum = "(#{datum}.nil? ? '' : #{datum}.text)"
        end
        datum
      end

      # Returns the data type of the column if the column is in the database
      def datatype
        @options[:datatype] || (@column ? @column.type : nil)
      end

      def enumerize?
        false
      end

      def state_machine?
        false
      end

      def numeric?
        [:decimal, :integer, :float, :numeric].include? datatype
      end

      # Returns the size/length of the column if the column is in the database
      def limit
        @column[:limit] if @column
      end

      # Defines if column is exportable
      def exportable?
        true
      end

      # Check if a column is sortable
      def sortable?
        return true
        # not self.action? and
        #!options[:through] && !@column.nil?
      end

      # Generate code in order to get the (foreign) record of the column
      def record_expr(record = 'record_of_the_death')
        record
      end

      def sort_expression
        fail NotImplementedError, 'sort_expression must be implemented'
      end
    end
  end
end
