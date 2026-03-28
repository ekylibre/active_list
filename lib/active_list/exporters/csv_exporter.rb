module ActiveList
  module Exporters
    class CsvExporter < AbstractExporter

      def file_extension
        'csv'
      end

      def mime_type
        Mime[:csv]
      end

      def generate_data_code
        record = 'r'
        code = generator.select_data_code(paginate: false)
        code << "data = ::CSV.generate do |csv|\n"
        code << "  csv << [#{columns_to_array(:header).join(', ')}]\n"
        code << "  for #{record} in #{generator.records_variable_name}\n"
        code << "    csv << [#{columns_to_array(:body, record: record).join(', ')}]\n"
        code << "  end\n"
        code << "end\n"
        code.c
      end

      def send_data_code
        "send_data(data, type: #{mime_type.to_s.inspect}, disposition: 'inline', filename: file_name.parameterize + '.#{file_extension}')\n".c
      end
    end
  end
end
