# encoding: UTF-8

require 'rodf'

# Register ODS format unless is already set
Mime::Type.register('application/vnd.oasis.opendocument.spreadsheet', :ods) unless defined? Mime::ODS

module ActiveList
  module Exporters
    class OpenDocumentSpreadsheetExporter < AbstractExporter

      def file_extension
        'ods'
      end

      def mime_type
        Mime[:ods]
      end

      def generate_data_code
        record = 'r'

        code = generator.select_data_code(paginate: false)
        code << <<~RUBY
          records = #{generator.records_variable_name}
          data = RODF::Spreadsheet.new

          data.instance_eval do
            office_style :head, family: :cell do
              property :text, 'font-weight': :bold
              property :paragraph, 'text-align': :center
            end

            table #{table.model.name}.model_name.human do
              row do
                #{columns_to_array(:header)}.each do |header|
                  cell header, style: :head
                end
              end

              for #{record} in records
                row do
                  #{columns_to_array(:body, record: record)}.each do |value|
                    cell value
                  end
                end
              end
            end
          end
        RUBY
        code.c
      end

      def send_data_code
        "send_data(data.bytes, type: #{mime_type.to_s.inspect}, disposition: 'inline', filename: file_name.parameterize + '.#{file_extension}')\n".c
      end
    end
  end
end
