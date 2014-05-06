module ActiveList

  module Renderers

    class SimpleRenderer < AbstractRenderer
      include ActiveList::Helpers


      DATATYPE_ABBREVIATION = {
        :binary => :bin,
        :boolean => :bln,
        :date => :dat,
        :datetime => :dtt,
        :decimal => :dec,
        :measure => :dec,
        :float => :flt,
        :integer => :int,
        :string => :str,
        :text => :txt,
        :time => :tim,
        :timestamp => :dtt
      }

      def remote_update_code
        code  = "if params[:column] and params[:visibility]\n"
        code << "  column = params[:column].to_sym\n"
        # Removes potentially unwanted columns
        code << "  #{var_name(:params)}[:hidden_columns].delete_if{|c| !#{table.data_columns.map(&:name).inspect}.include?(c)}\n"
        code << "  #{var_name(:params)}[:hidden_columns].delete(column) if params[:visibility] == 'shown'\n"
        code << "  #{var_name(:params)}[:hidden_columns] << column if params[:visibility] == 'hidden'\n"
        code << "  head :ok\n"
        code << "elsif params[:only]\n"
        code << "  render(:inline => '<%=#{generator.view_method_name}(:only => params[:only])-%>')\n"
        code << "else\n"
        code << "  render(:inline => '<%=#{generator.view_method_name}-%>')\n"
        code << "end\n"
        return code
      end

      def build_table_code
        record = "r"
        child  = "c"

        # colgroup = columns_definition_code
        header = header_code
        extras = extras_code

        code  = generator.select_data_code
        code << "#{var_name(:tbody)} = '<tbody data-total=\"'+#{var_name(:count)}.to_s+'\""
        if table.paginate?
          code << " data-per-page=\"'+#{var_name(:limit)}.to_s+'\""
          code << " data-pages-count=\"'+#{var_name(:last)}.to_s+'\""
        end
        code << ">'\n"
        code << "if #{var_name(:count)} > 0\n"
        code << "  for #{record} in #{generator.records_variable_name}\n"
        line_class = ""
        if table.options[:line_class]
          line_class = ", class: (" + recordify!(table.options[:line_class], record) + ").to_s"
        end
        code << "    #{var_name(:tbody)} << content_tag(:tr, id: 'r' + #{record}.id.to_s#{line_class}) do\n"
        code << columns_to_cells(:body, record: record).dig(3)
        code << "    end\n"
        # if table.options[:children].is_a? Symbol
        #   children = table.options[:children].to_s
        #   code << "    for #{child} in #{record}.#{children}\n"
        #   code << "      #{var_name(:tbody)} << content_tag(:tr, :class => #{line_class}+' child') do\n"
        #   code << columns_to_cells(:children, table.children, record: child).dig(4)
        #   code << "      end\n"
        #   code << "    end\n"
        # end
        code << "  end\n"
        code << "else\n"
        code << "  #{var_name(:tbody)} << '<tr class=\"empty\"><td colspan=\"#{table.columns.size+1}\">' + ::I18n.translate('list.no_records') + '</td></tr>'\n"
        code << "end\n"

        code << "#{var_name(:tbody)} << '</tbody>'\n"
        code << "return #{var_name(:tbody)}.html_safe if options[:only] == 'table-body'\n"
        
        # Build content
        code << "#{var_name(:content)} = ''\n"
        code << "#{var_name(:content)} << #{extras}\n" unless extras.blank?
        code << "#{var_name(:content)} << '<table class=\"list\""
        if table.paginate?
          code << " data-list-current-page=\"' + #{var_name(:page)}.to_s + '\" data-list-page-size=\"' + #{var_name(:limit)}.to_s + '\""
        end
        code << " data-list-sort-by=\"' + #{var_name(:params)}[:sort].to_s + '\" data-list-sort-dir=\"' + #{var_name(:params)}[:dir].to_s + '\""
        code << ">'\n"
        code << "#{var_name(:content)} << (#{header})\n"
        code << "if block_given?\n"
        code << "  #{var_name(:content)} << '<tfoot>' + capture(" + table.columns.collect{|c| {name: c.name, id: c.id}}.inspect + ", &block).to_s + '</tfoot>'\n"
        code << "end\n"
        code << "#{var_name(:content)} << #{var_name(:tbody)}\n"
        code << "#{var_name(:content)} << '</table>'\n"
        code << "return #{var_name(:content)}.html_safe if options[:only] == 'content'\n"

        # Build whole
        code << "return ('<div id=\"#{table.name}\" data-list-source=\"'+h(url_for(options.merge(:action => '#{generator.controller_method_name}')))+'\" class=\"active-list\">' + #{var_name(:content)} + '</div>').html_safe\n"
        return code
      end



      def columns_to_cells(nature, options={})
        code = ''
        unless [:body, :children].include?(nature)
          raise ArgumentError, "Nature is invalid"
        end
        record = options[:record] || 'record_of_the_death'
        if table.selectable?
          code << "content_tag(:td, class: 'list-selector') do\n"
          code << "  tag(:input, type: 'checkbox', value: #{record}.id, data: {list_selector: #{record}.id})\n"
          code << "end +\n"
        end

        children_mode = !!(nature == :children)
        for column in table.columns
          value_code = ""
          if column.is_a? ActiveList::Definition::EmptyColumn
            value_code = 'nil'
          elsif column.is_a? ActiveList::Definition::StatusColumn

            value_code = column.datum_code(record, children_mode)
            levels = %w(go caution stop)
            lights = levels.collect do |light|
              "content_tag(:span, '', :class => #{light.inspect})"
            end.join(" + ")
            # Expected value are :valid, :warning, :error
            value_code = "content_tag(:span, #{lights}, :class => 'lights lights-' + (#{levels.inspect}.include?(#{value_code}.to_s) ? #{value_code}.to_s : 'undefined'))"

          elsif column.is_a? ActiveList::Definition::DataColumn
            if column.options[:children].is_a? FalseClass and children_mode
              value_code = 'nil'
            else
              value_code = column.datum_code(record, children_mode)
              if column.datatype == :boolean
                value_code = "content_tag(:div, '', :class => 'checkbox-'+("+value_code.to_s+" ? 'true' : 'false'))"
              elsif [:date, :datetime, :timestamp, :measure].include? column.datatype
                value_code = "(#{value_code}.nil? ? '' : #{value_code}.l)"
              elsif [:item].include? column.datatype
                value_code = "(#{value_code}.nil? ? '' : #{value_code}.human_name)"
              end
              if !column.options[:currency].is_a?(FalseClass) and currency = column.options[:currency]
                currency = currency[nature] if currency.is_a?(Hash)
                currency = :currency if currency.is_a?(TrueClass)
                # currency = "#{record}.#{currency}".c if currency.is_a?(Symbol)
                currency = "#{column.record_expr(record)}.#{currency}".c if currency.is_a?(Symbol)
                value_code = "(#{value_code}.nil? ? '' : #{value_code}.l(currency: #{currency.inspect}))"
              elsif column.datatype == :decimal
                value_code = "(#{value_code}.nil? ? '' : #{value_code}.l)"
              elsif column.enumerize?
                value_code = "(#{value_code}.nil? ? '' : #{value_code}.text)"
              end
              if column.options[:url] and nature == :body
                column.options[:url] = {} unless column.options[:url].is_a?(Hash)
                column.options[:url][:id] ||= (column.record_expr(record)+'.id').c
                column.options[:url][:action] ||= :show
                column.options[:url][:controller] ||= column.class_name.tableize.to_sym # (self.generator.collection? ? "RECORD.class.name.tableize".c : column.class_name.tableize.to_sym)
                # column.options[:url][:controller] ||= "#{value_code}.class.name.tableize".c
                url = column.options[:url].collect{|k, v| "#{k}: " + urlify(v, record)}.join(", ")
                value_code = "(#{value_code}.blank? ? '' : link_to(#{value_code}.to_s, #{url}))"
              elsif column.options[:mode]||column.label_method == :email
                value_code = "(#{value_code}.blank? ? '' : mail_to(#{value_code}))"
              elsif column.options[:mode]||column.label_method == :website
                value_code = "(#{value_code}.blank? ? '' : link_to("+value_code+", "+value_code+"))"
              elsif column.label_method == :color
                value_code = "content_tag(:div, #{column.datum_code(record)}, style: 'background: #'+"+column.datum_code(record)+")"
              elsif column.label_method.to_s.match(/(^|\_)currency$/) and column.datatype == :string
                value_code = "(Nomen::Currencies[#{value_code}] ? Nomen::Currencies[#{value_code}].human_name : #{value_code})"
              elsif column.label_method.to_s.match(/(^|\_)language$/) and column.datatype == :string
                value_code = "(Nomen::Languages[#{value_code}]  ? Nomen::Languages[#{value_code}].human_name : #{value_code})"
              elsif column.label_method.to_s.match(/(^|\_)country$/)  and column.datatype == :string
                value_code = "(Nomen::Countries[#{value_code}]  ? (image_tag('countries/' + #{value_code}.to_s + '.png') + ' ' + Nomen::Countries[#{value_code}].human_name).html_safe : #{value_code})"
              else # if column.datatype == :string
                value_code = "h(" + value_code + ".to_s)"
              end

              value_code = "if #{record}\n" + value_code.dig + "end" if column.is_a?(ActiveList::Definition::AssociationColumn)
            end
          elsif column.is_a?(ActiveList::Definition::CheckBoxColumn)
            if nature == :body
              form_name = column.form_name || "'#{table.name}[' + #{record}.id.to_s + '][#{column.name}]'".c
              value = "nil"
              if column.form_value
                value = recordify(column.form_value, record)
              else
                value = 1
                value_code << "hidden_field_tag(#{form_name.inspect}, 0, id: nil) + \n"
              end
              value_code << "check_box_tag(#{form_name.inspect}, #{value}, #{recordify!(column.options[:value] || column.name, record)})" # , id: '#{table.name}_'+#{record}.id.to_s+'_#{column.name}'
            else
              value_code << "nil"
            end
          elsif column.is_a?(ActiveList::Definition::TextFieldColumn)
            form_name = column.form_name || "'#{table.name}[' + #{record}.id.to_s + '][#{column.name}]'".c
            value_code = (nature == :body ? "text_field_tag(#{form_name.inspect}, #{recordify!(column.options[:value] || column.name, record)}#{column.options[:size] ? ', size: ' + column.options[:size].to_s : ''})" : "nil") # , id: '#{table.name}_'+#{record}.id.to_s + '_#{column.name}'
          elsif column.is_a?(ActiveList::Definition::ActionColumn)
            next unless column.use_single?
            value_code = (nature == :body ? column.operation(record) : "nil")
          else
            value_code = "'&#160;&#8709;&#160;'.html_safe"
          end
          code << "content_tag(:td, :class => \"#{column_classes(column)}\") do\n"
          code << value_code.dig
          code << "end +\n"
        end
        # if nature == :header
        #   code << "'<th class=\"spe\">#{menu_code}</th>'"
        # else
        #   code << "content_tag(:td)"
        # end

        code << "''.html_safe"
        # code << "content_tag(:td)"
        return code.c
      end


      # Produces main menu code
      def menu_code
        menu = "<span class=\"settings\">"
        menu << "<a class=\"settings-start\"><i></i>' + h('list.menu'.t) + '</a>"
        menu << "<ul>"
        if table.paginate?
          # Per page
          list = [5, 10, 20, 50, 100, 200]
          list << table.options[:per_page].to_i if table.options[:per_page].to_i > 0
          list = list.uniq.sort
          menu << "<li class=\"parent\">"
          menu << "<a class=\"pages\"><i></i>' + h('list.items_per_page'.t) + '</a><ul>"
          for n in list
            menu << "<li data-list-change-page-size=\"#{n}\" '+(#{var_name(:params)}[:per_page] == #{n} ? ' class=\"check\"' : '') + '><a><i></i>' + h('list.x_per_page'.t(count: #{n})) + '</a></li>"
          end
          menu << "</ul></li>"
        end

        # Column selector
        menu << "<li class=\"parent\">"
        menu << "<a class=\"columns\"><i></i>' + h('list.columns'.t) + '</a><ul>"
        for column in table.data_columns
          menu << "<li data-list-toggle-column=\"#{column.name}\" class=\"' + (#{var_name(:params)}[:hidden_columns].include?(:#{column.name}) ? 'unchecked' : 'checked') + '\"><a><i></i>' + h(#{column.header_code}) + '</a></li>"
        end
        menu << "</ul></li>"

        # Separator
        menu << "<li class=\"separator\"></li>"
        # Exports
        for format, exporter in ActiveList.exporters
          menu << "<li class=\"export export-#{format}\">' + link_to(content_tag(:i) + h('list.export_as'.t(exported: :#{format}.t(scope: 'list.export.formats'))), params.merge(action: :#{generator.controller_method_name}, sort: #{var_name(:params)}[:sort], dir: #{var_name(:params)}[:dir], format: '#{format}')) + '</li>"
        end
        menu << "</ul></span>"
        return menu
      end

      # Produces the code to create the header line using  top-end menu for columns
      # and pagination management
      def header_code
        code = "'<thead><tr>"
        if table.selectable?
          code << "<th class=\"list-selector\"></th>"
        end
        for column in table.columns
          next if column.is_a?(ActiveList::Definition::ActionColumn) and !column.use_single?
          code << "<th data-list-column=\"#{column.sort_id}\""
          code << " data-list-column-cells=\"#{column.short_id}\""
          code << " data-list-column-sort=\"'+(#{var_name(:params)}[:sort] != '#{column.sort_id}' ? 'asc' : #{var_name(:params)}[:dir] == 'asc' ? 'desc' : 'asc')+'\"" if column.sortable?
          code << " class=\"#{column_classes(column, true, true)}\""
          code << ">"
          code << "' + h(#{column.header_code}) + '"
          code << "<i></i>"
          code << "</th>"
        end
        # code << "<th class=\"spe\">#{menu_code}</th>"
        code << "</tr></thead>'"
        return code
      end

      # Produces the code to create bottom menu and pagination
      def extras_code
        code = []

        if table.global_action_columns.any?
          actioner = ""
          actioner << "<span class=\"actioner\">'"
          for column in table.global_action_columns
            actioner << " + link_to(content_tag(:i) + h(' ' + :#{column.name.to_s}.t(scope: 'rest.actions')), #{column.default_url.inspect}, class: 'btn btn-#{column.name}'#{', style: "display: none"' unless column.use_none?}#{', method: "' + column.options[:method].to_s + '"' if column.options[:method]}, data: {list_actioner: :#{column.use_none? ? 'none' : 'many'}#{', confirm: :' + column.options[:confirm].to_s + '.t(scope: "labels")' if column.options[:confirm]}})"
          end
          actioner << " + '</span>"
          code << "'#{actioner}'"
        end

        code << "'#{menu_code}'"

        if table.paginate?
          pagination = ""
          current_page = "#{var_name(:page)}"
          last_page = "#{var_name(:last)}"

          pagination << "<span class=\"pagination\">"
          pagination << "<span class=\"status\">' + 'list.pagination.x_to_y_of_total'.t(x: (#{var_name(:offset)} + (#{var_name(:count)} > 0 ? 1 : 0)), y: ((#{var_name(:last)} == #{var_name(:page)}) ? #{var_name(:count)} : #{var_name(:offset)} + #{var_name(:limit)}), total: #{var_name(:count)}) + '</span>"

          pagination << "<span class=\"paginator\">"

          pagination << "<a href=\"#\" data-list-move-to-page=\"1\" class=\"btn first-page\"' + (#{current_page} != 1 ? '' : ' disabled=\"true\"') + '><i></i>' + ::I18n.translate('list.pagination.first') + '</a>"
          pagination << "<a href=\"#\" data-list-move-to-page=\"' + (#{current_page} - 1).to_s + '\" class=\"btn previous-page\"' + (#{current_page} != 1 ? '' : ' disabled=\"true\"') + '><i></i>' + ::I18n.translate('list.pagination.previous') + '</a>"

          x = '@@PAGE-NUMBER@@'
          y = '@@PAGE-COUNT@@'
          # pagination << "<span class=\"paginator\">'+::I18n.translate('list.page_x_on_y', :default => '%{x} / %{y}', :x => '#{x}', :y => '#{y}').html_safe.gsub('#{x}', ('<input type=\"number\" size=\"4\" data-list-move-to-page=\"value\" value=\"'+#{var_name(:page)}.to_s+'\">').html_safe).gsub('#{y}', #{var_name(:last)}.to_s) + '</span>"
          # pagination << "<input type=\"number\" size=\"4\" data-list-move-to-page=\"value\" value=\"' + #{var_name(:page)}.to_s + '\">"

          pagination << "<a href=\"#\" data-list-move-to-page=\"' + (#{current_page} + 1).to_s + '\" class=\"btn next-page\"' + (#{current_page} != #{last_page} ? '' : ' disabled=\"true\"') + '><i></i>' + ::I18n.translate('list.pagination.next')+'</a>"
          pagination << "<a href=\"#\" data-list-move-to-page=\"' + (#{last_page}).to_s + '\" class=\"btn last-page\"' + (#{current_page} != #{last_page} ? '' : ' disabled=\"true\"') + '><i></i>' + ::I18n.translate('list.pagination.last')+'</a>"
          pagination << "</span>"

          # pagination << "<span class=\"separator\"></span>"


          code << "'#{pagination}'"
        end

        unless code.empty?
          code = "content_tag(:div, (#{code.join(' + ')}).html_safe, class: 'list-control')"
        end

        return code
      end


      # # Not used
      # def columns_definition_code
      #   code = table.columns.collect do |column|
      #     "<col id=\\\"#{column.unique_id}\\\" class=\\\"#{column_classes(column, true)}\\\" data-cells-class=\\\"#{column.short_id}\\\" href=\\\"\#\{url_for(:action => :#{generator.controller_method_name}, :column => #{column.id.to_s.inspect})\}\\\" />"
      #   end.join
      #   return "\"#{code}\""
      # end

      # Finds all default styles for column
      def column_classes(column, without_id = false, without_interpolation = false)
        classes, conds = [], []
        conds << [:sor, "#{var_name(:params)}[:sort] == '#{column.sort_id}'".c] if column.sortable?
        conds << [:hidden, "#{var_name(:params)}[:hidden_columns].include?(:#{column.name})".c] if column.is_a? ActiveList::Definition::DataColumn
        classes << column.options[:class].to_s.strip unless column.options[:class].blank?
        classes << column.short_id unless without_id
        if column.is_a? ActiveList::Definition::ActionColumn
          classes << :act
        elsif column.is_a? ActiveList::Definition::StatusColumn
          classes << :status
        elsif column.is_a? ActiveList::Definition::DataColumn
          classes << :col
          classes << DATATYPE_ABBREVIATION[column.datatype]
          classes << :url if column.options[:url].is_a?(Hash)
          classes << column.label_method if [:code, :color].include? column.label_method.to_sym
          if column.options[:mode] == :download
            classes << :dld
          elsif column.options[:mode]||column.label_method == :email
            classes << :eml
          elsif column.options[:mode]||column.label_method == :website
            classes << :web
          end
        elsif column.is_a? ActiveList::Definition::TextFieldColumn
          classes << :tfd
        elsif column.is_a? ActiveList::Definition::CheckBoxColumn
          classes << :chk
        else
          classes << :unk
        end
        html = classes.join(' ').strip
        if conds.size > 0
          if without_interpolation
            html << "' + "
            html << conds.collect do |c|
              "(#{c[1]} ? ' #{c[0]}' : '')"
            end.join(' + ')
            html << " + '"
          else
            html << conds.collect do |c|
              "\#\{' #{c[0]}' if #{c[1]}\}"
            end.join
          end
        end
        return html
      end


    end


  end

end
