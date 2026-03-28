module ActiveList
  module Definition
    class EmptyColumn < AbstractColumn

      def header_code
        "#{name.to_s.strip.inspect}.t(scope: 'labels')".c
      end
    end
  end
end
