module ActiveList
  module Exporters
    class AbstractExporter
      attr_reader :table, :generator

      def initialize(generator)
        @generator = generator
        @table = generator.table
      end

      def file_extension
        'txt'
      end

      def file_name_code
        "file_name = #{table.model.name}.model_name.human\n".c
      end

      def mime_type
        Mime::TEXT
      end

      def generate_file_code(format)
        code = file_name_code
        if generator.export_class
          code << generator.exportable_query_code
          code << "#{generator.export_class}.perform_later(user: current_user,\n"
          code << "                                        query: query,\n"
          code << "                                        content: #{columns_to_hash},\n"
          code << "                                        file_name: file_name,\n"
          code << "                                        format: '#{format}',\n"
          code << "                                        file_extension: '#{file_extension}')\n"
          code << "notify_success(:document_in_preparation)\n"
          code << "redirect_back(fallback_location: root_path)\n"
        else
          code << generate_data_code
          code << send_data_code
        end
        code.c
      end

      def send_data_code
        raise NotImplementedError.new("#{self.class.name}#send_data_code must be implemented in sub-classes.")
      end

      def generate_data_code
        raise NotImplementedError.new("#{self.class.name}#generate_data_code must be implemented in sub-classes.")
      end

      def columns_headers(options = {})
        headers = []
        columns = table.exportable_columns
        for column in columns
          datum = column.header_code
          headers << (options[:encoding] ? datum + ".to_s.encode('#{options[:encoding]}', invalid: :replace, undef: :replace)" : datum)
        end
        headers
      end

      def columns_to_array(nature, options = {})
        columns = table.exportable_columns

        array = []
        record = options[:record] || 'record_of_the_death'
        for column in columns
          next unless column.is_a?(ActiveList::Definition::AbstractColumn)
          datum = if nature == :header
                    column.header_code
                  else
                    column.exporting_datum_code(record)
                  end
          array << (options[:encoding] ? datum + ".to_s.encode('#{options[:encoding]}', invalid: :replace, undef: :replace)" : datum)
        end
        array
      end

      def columns_to_hash
        table.exportable_columns.map do |column|
          [column.header_code, column.exporting_datum_code('record', true).to_s]
        end.to_h
      end
    end
  end
end
