module ActiveList
  # Manage data query
  class Generator
    # Generate select code for the table taking all parameters in account
    def select_data_code(options = {})
      paginate = (options.key?(:paginate) ? options[:paginate] : @table.paginate?)
      # Check order
      unless @table.options.keys.include?(:order)
        columns = @table.table_columns
        @table.options[:order] = (columns.any? ? columns.first.name.to_sym : { id: :desc })
      end

      class_name = @table.model.name
      class_name = "(controller_name != '#{class_name.tableize}' ? controller_name.to_s.classify.constantize : #{class_name})" if collection?

      # Find data
      query_code = class_name.to_s
      query_code << scope_code if scope_code
      query_code << ".select(#{select_code})" if select_code
      query_code << ".from(#{from_code})" if from_code
      query_code << ".where(#{conditions_code})" unless @table.options[:conditions].blank?
      query_code << ".joins(#{@table.options[:joins].inspect})" unless @table.options[:joins].blank?
      unless includes_reflections.empty?
        expr = includes_reflections.inspect[1..-2]
        query_code << ".includes(#{expr})"
        query_code << ".references(#{expr})"
      end

      code = ''
      code << "#{query_code}\n"

      code << if @table.options[:count].present?
                "#{var_name(:count)} = #{query_code}.count(#{@table.options[:count].inspect})\n"
              else
                "#{var_name(:count)} = #{query_code}.count\n"
              end
      query_code << ".group(#{@table.options[:group].inspect})" unless @table.options[:group].blank?
      query_code << ".reorder(#{var_name(:order)})"

      if paginate
        code << "#{var_name(:limit)}  = (#{var_name(:params)}[:per_page] || 25).to_i\n"

        code << "if params[:page]\n"
        code << "  #{var_name(:page)} = (#{var_name(:params)}[:page] || 1).to_i\n"
        code << "elsif params['#{table.name}-id'] and #{var_name(:index)} = #{query_code}.pluck(:id).index(params['#{table.name}-id'].to_i)\n"
        # Find page of request element
        code << "  #{var_name(:page)} = (#{var_name(:index)}.to_f / #{var_name(:limit)}).floor + 1\n"
        code << "else\n"
        code << "  #{var_name(:page)} = 1\n"
        code << "end\n"
        code << "#{var_name(:page)}   = 1 if #{var_name(:page)} < 1\n"

        code << "#{var_name(:offset)} = (#{var_name(:page)} - 1) * #{var_name(:limit)}\n"
        code << "#{var_name(:last)}   = (#{var_name(:count)}.to_f / #{var_name(:limit)}).ceil.to_i\n"
        code << "#{var_name(:last)}   = 1 if #{var_name(:last)} < 1\n"

        code << "return #{view_method_name}(options.merge(page: 1)) if 1 > #{var_name(:page)}\n"
        code << "return #{view_method_name}(options.merge(page: #{var_name(:last)})) if #{var_name(:page)} > #{var_name(:last)}\n"
        query_code << ".offset(#{var_name(:offset)})"
        query_code << ".limit(#{var_name(:limit)})"
      end

      code << "#{records_variable_name} = #{query_code} || {}\n"
      code
    end

    protected

    # Compute includes Hash
    def includes_reflections
      hash = []
      @table.columns.each do |column|
        hash << column.reflection.name if column.respond_to?(:reflection)
      end
      hash
    end

    def scope_code
      return nil unless scopes = @table.options[:scope]
      scopes = [scopes].flatten
      code = ''
      scopes.each do |scope|
        code << ".#{scope}"
      end
      code
    end

    # Generate the code from a conditions option
    def conditions_code
      conditions = @table.options[:conditions]
      code = ''
      case conditions
      when Array
        case conditions[0]
        when String # SQL
          code << '[' + conditions.first.inspect
          code << conditions[1..-1].collect { |p| ', ' + sanitize_condition(p) }.join if conditions.size > 1
          code << ']'
        when Symbol # Method
          raise 'What?' # Amazingly explicit.
        # code << conditions.first.to_s + '('
        # code << conditions[1..-1].collect { |p| sanitize_condition(p) }.join(', ') if conditions.size > 1
        # code << ')'
        else
          raise ArgumentError, 'First element of an Array can only be String or Symbol.'
        end
      when Hash # SQL
        code << '{' + conditions.collect { |key, value| key.to_s + ': ' + sanitize_condition(value) }.join(',') + '}'
      when Symbol # Method
        code << conditions.to_s + '(options)'
      when CodeString
        code << '(' + conditions.gsub(/\s*\n\s*/, ';') + ')'
      when String
        code << conditions.inspect
      else
        raise ArgumentError, "Unsupported type for conditions: #{conditions.inspect}"
      end
      code
    end

    def from_code
      return nil unless @table.options[:from]
      from = @table.options[:from]
      code = ''
      code << '(' + from.gsub(/\s*\n\s*/, ';') + ')'
      code
    end

    def select_code
      return nil unless @table.options[:distinct] || @table.options[:select]
      code = ''
      code << 'DISTINCT ' if @table.options[:distinct]
      if @table.options[:select]
        # code << @table.options[:select].collect { |k, v| ", #{k[0].to_s + '.' + k[1].to_s} AS #{v}" }.join
        code << @table.options[:select].collect do |k, v|
          c = if k.is_a? Array
                k[0].to_s + '.' + k[1].to_s
              else
                k
              end
          c += " AS #{v}" unless v.blank?
          c
        end.join(', ')
      else
        code << "#{@table.model.table_name}.*"
      end
      ("'" + code + "'").c
    end

    def sanitize_condition(value)
      # if value.is_a? Array
      #   # if value.size==1 and value[0].is_a? String
      #   #   value[0].to_s
      #   # else
      #   value.inspect
      #   # end
      # elsif value.is_a? CodeString
      #   value.inspect
      # elsif value.is_a? String
      #   '"' + value.gsub('"', '\"') + '"'
      # els
      if [Date, DateTime].include? value.class
        '"' + value.to_formatted_s(:db) + '"'
      elsif value.is_a? NilClass
        'nil'
      else
        value.inspect
      end
    end
  end
end
