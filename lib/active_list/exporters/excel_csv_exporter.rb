# Register XCSV format unless is already set
Mime::Type.register('text/csv', :xcsv) unless defined? Mime::XCSV

module ActiveList
  module Exporters
    class ExcelCsvExporter < CsvExporter

      def file_extension
        'csv'
      end

      def mime_type
        Mime[:xcsv]
      end

      def generate_data_code
        record = 'r'
        code = generator.select_data_code(paginate: false)
        encoding = 'CP1252'
        code << "data = ::CSV.generate(col_sep: ';') do |csv|\n"
        code << "  csv << [#{columns_to_array(:header, encoding: encoding).join(', ')}]\n"
        code << "  for #{record} in #{generator.records_variable_name}\n"
        code << "    csv << [#{columns_to_array(:body, record: record, encoding: encoding).join(', ')}]\n"
        code << "  end\n"
        code << "end\n"
        code.c
      end
    end
  end
end
