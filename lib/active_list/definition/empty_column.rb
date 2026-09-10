module ActiveList
  module Definition
    class EmptyColumn < AbstractColumn

      def header_code
        "::I18n.translate(#{name.to_s.strip.inspect}, scope: 'labels')".c
      end
    end
  end
end
