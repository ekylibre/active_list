module ActiveList
  module Helpers
    def recordify!(value, record_name)
      if value.is_a?(Symbol)
        record_name + '.' + value.to_s
      elsif value.is_a?(CodeString)
        '(' + value.gsub(/RECORD/, record_name) + ')'
      else
        raise ArgumentError, 'CodeString or Symbol must be given to be recordified)'
      end
    end

    def recordify(value, record_name)
      if value.is_a?(Symbol)
        record_name + '.' + value.to_s
      elsif value.is_a?(CodeString)
        '(' + value.gsub(/RECORD/, record_name) + ')'
      else
        value.inspect
      end
    end

    def urlify(key, value, record_name, namespace = nil)
      return value.inspect unless value.is_a?(CodeString)
      if key == :controller && namespace
        '(' + "'/#{namespace}/' + " + value.gsub(/RECORD/, record_name) + ')'
      else
        '(' + value.gsub(/RECORD/, record_name) + ')'
      end
    end
  end
end
