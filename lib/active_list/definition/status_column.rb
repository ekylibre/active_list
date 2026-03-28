module ActiveList
  module Definition
    class StatusColumn < AttributeColumn
      def initialize(table, name, options = {})
        super

        @tooltip_method = options.fetch(:tooltip_method, nil)
      end

      def tooltip_title_code(record, child)
        c = if @tooltip_method.nil?
          "#{record}.try(:human_status) || #{record}&.try(:human_state_name) || #{datum_value(record, child)}.to_s.capitalize"
        else
          "#{record}.#{@tooltip_method}"
        end
      end
    end
  end
end
