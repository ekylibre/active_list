module ActiveList
  module Definition
    class IconColumn < AbstractColumn
      include ActiveList::Helpers

      def header_code
        "''".c
      end

      def icon_code(record = 'record_of_the_death')
        code = "content_tag(:i)"
        if @options[:if]
          code = 'if ' + recordify!(@options[:if], record) + "\n" + code.dig + 'end'
        end
        code.c
      end
    end
  end
end

