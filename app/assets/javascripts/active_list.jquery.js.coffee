ActiveList = {}

(($, AL) ->
  "use strict"

  # Main function which reload table with specified data parameters
  AL.refresh = (list, options) ->
    table = list.find("table[data-current-page]").first()
    parameters =
      sort:     table.data("list-sort-by")
      dir:      table.data("list-sort-dir")
      page:     table.data("list-current-page")
      per_page: table.data("list-page-size")
      only:     "content"
      redirect: list.data("list-redirect")
    list_id = list.attr('id')
    $.extend parameters, options
    url = list.data("list-source")
    $.ajax url,
      data: parameters
      dataType: "html"
      success: (data, status, request) ->
        content = $(data)
        list_data = content.find(".list-data")
        list_control = content.find(".list-control")
        for type in ["actions", "pagination", "settings"]
          $("*[data-list-ref='#{list_id}'].list-#{type}").replaceWith list_control.find(".list-#{type}")
        list.find(".list-data").html(list_data)
        selection = list.prop('selection')
        if selection?
          for id in Object.keys(selection)
            list.find("input[data-list-selector='#{id}']")
              .attr('checked', 'checked')
              .closest('tr').addClass('selected')
          AL.updateResults list
          AL.checkGlobalButtons list
        list.trigger('page:change')
        $(document).trigger('list:page:change')
        true

    false

  values_for_computation_of_rows = (list, row, existing_hash) ->
    computes = {}
    computes = existing_hash if existing_hash?
    for cell in row.find('td')
      continue unless AL.computation_for(list, cell)?
      col_number = AL.column_number(list, cell)
      computes[col_number] = [] unless computes[col_number]?
      computes[col_number].push parseFloat(AL.unaltered_value(cell))
    computes

  AL.column_for = (list, cell) ->
    if typeof(cell) == "string"
      column = cell
    else
      column = $(cell).data('list-column-header')
    list.find("th[data-list-column-cells='#{column}']")

  AL.computation_for = (list, cell) ->
    AL.column_for(list, cell).data('list-column-computation')

  AL.column_number = (list, cell) ->
    AL.column_for(list, cell).data('list-column-cells')

  AL.unaltered_value = (cell) ->
    $(cell).data('list-cell-value')

  # Select a row of "many" buttons
  AL.select = (checkbox) ->
    list = checkbox.closest('*[data-list-source]')
    row = checkbox.closest('tr')
    selection = if list.prop('selection')? then list.prop('selection') else {}
    key = checkbox.data('list-selector')
    present = String(key) in Object.keys(selection)
    if checkbox.is ":checked"
      selection[key] = values_for_computation_of_rows(list, row, selection[key]) unless present
      row.addClass("selected")
    else
      delete selection[key] if present
      row.removeClass("selected")
    list.prop('selection', selection)

    AL.updateResults list
    AL.checkGlobalButtons list

  AL.updateResults = (list) ->
    results = {}
    selection = if list.prop('selection')? then list.prop('selection') else {}
    for key, columns of selection
      for column, values of columns
        computation = AL.computation_for(list, column)
        unless computation == 'sum' || computation == 'average'
          console.log "Don't know how to handle computation #{computation}. Skipping."
          continue
        results[column] = [] if typeof(results[column]) == "undefined"
        results[column] = results[column].concat values

    for column, values of results
      float_values = (parseFloat(e) for e in values)
      total = values.reduce (t, s) -> t + s
      total /= values.length if AL.computation_for(list, column) == 'average'
      list.attr("data-list-result-#{column}", total)
      unit_precision = parseInt(AL.column_for(list, column).data('list-column-unit-precision'))
      unit_symbol    = AL.column_for(list, column).data('list-column-unit-symbol')
      if unit_precision and unit_symbol
        magnitude = Math.pow(10, unit_precision)
        rounded = Math.round(total * magnitude) / magnitude
        displayable_total = "#{rounded.toFixed(unit_precision)} #{unit_symbol}"
      list.find("#computation-results td[data-list-result-for=\"#{column}\"] #list-computation-result").html(displayable_total)
    for column in list.find("th[data-list-column-computation]")
      col_number = $(column).data('list-column-cells')
      continue unless typeof(results[col_number]) == "undefined" or results[col_number].length == 0
      list.removeAttr("data-list-result-#{col_number}")
      list.find("#computation-results td[data-list-result-for=\"#{col_number}\"] #list-computation-result").html('')

  # Hide/show needed global buttons
  AL.checkGlobalButtons = (list) ->
    selection = list.prop('selection')
    list_id = list.attr('id')
    actions = $("*[data-list-ref='#{list_id}']")
    caption = $(list).find("tr.selected-count th")
    length = Object.keys(selection).length
    console.log("HELLO")
    caption.text(caption.text().replace(new RegExp('(##NUM##|\\d+)'), length))
    console.log "#{length}"
    if length > 0
      caption.parent().show()
      actions.find("*[data-list-actioner='none']:visible").hide()
      actions.find("*[data-list-actioner='none']:visible").hide()
      actions.find("*[data-list-actioner='many']:hidden").show()
    else
      caption.parent().hide()
      actions.find("*[data-list-actioner='none']:hidden").show()
      actions.find("*[data-list-actioner='many']:visible").hide()
    actions.find("*[data-list-actioner='many']").each (index) ->
      button = $(this)
      unless button.prop('hrefPattern')?
        button.prop('hrefPattern', button.attr('href'))
      pattern = button.prop('hrefPattern')
      url = pattern.replace(encodeURIComponent("##IDS##"), Object.keys(selection).join(','), 'g')
      button.attr("href", url)

  # Move to given page
  AL.moveToPage = (list, page) ->
    if isNaN(page)
      console.error "Cannot move to page #{page}. A number is expected"
    AL.refresh list,
      page: page
    false

  # Sort by one column
  $(document).on "click", "*[data-list-source] th[data-list-column][data-list-column-sort]", (event) ->
    sorter = $(this)
    list = sorter.closest("*[data-list-source]")
    AL.refresh list,
      sort: sorter.data("list-column")
      dir:  sorter.data("list-column-sort")
    false

  # Select row
  $(document).on "click", "*[data-list-source] td>input[data-list-selector]", (event) ->
    AL.select $(this)
    true

  # Adds title attribute based on link name
  $(document).on "hover", "*[data-list-source] tbody tr td.act a", (event) ->
    element = $(this)
    title = element.attr("title")
    element.attr "title", element.html() unless title?
    return

  # Change number of item per page
  $(document).on "click", "*[data-list-ref] *[data-list-change-page-size]", (event) ->
    sizer = $(this)
    per_page = sizer.data("list-change-page-size")
    if isNaN(per_page)
      console.error "@list-change-page-size attribute is not a number: #{per_page}"
    else
      list = $("##{sizer.closest('*[data-list-ref]').data('list-ref')}")
      list.prop('selection', {})
      AL.updateResults list
      AL.checkGlobalButtons list
      AL.refresh list,
        per_page: per_page
    false

  # Toggle visibility of a column
  $(document).on "click", "*[data-list-ref] *[data-list-toggle-column]", (event) ->
    toggler = $(this)
    visibility = ""
    columnId = toggler.data("list-toggle-column")
    list = $("##{toggler.closest('*[data-list-ref]').data('list-ref')}")
    column = list.find("th[data-list-column=\"#{columnId}\"]")

    className = column.data("list-column-cells")
    className = columnId unless className?
    search = ".#{className}"
    if column.hasClass("hidden")
      list.find(search).removeClass "hidden"
      column.removeClass "hidden"
      toggler.removeClass "unchecked"
      toggler.addClass "checked"
      visibility = "shown"
    else
      list.find(search).addClass "hidden"
      column.addClass "hidden"
      toggler.removeClass "checked"
      toggler.addClass "unchecked"
      visibility = "hidden"
    $.ajax list.data("list-source"),
      dataType: "html"
      data:
        visibility: visibility
        column: columnId
    false

  $(document).on "change", "input[data-list-selector=all]", (event) ->
    check = $(this).is(':checked')
    $(this).closest("table").find("td > input[data-list-selector]:not(:checked)").click() if check
    $(this).closest("table").find("td > input[data-list-selector]:checked").click() unless check

  # Change page of table on link clicks
  $(document).on "click", "*[data-list-ref] a[data-list-move-to-page]", (event) ->
    pager = $(this)
    list = $("##{pager.closest('*[data-list-ref]').data('list-ref')}")
    AL.moveToPage list, pager.data("list-move-to-page")

  # Change page of table on input changes
  $(document).on "change", "*[data-list-ref] input[data-list-move-to-page]", (event) ->
    pager = $(this)
    list = $("##{pager.closest('*[data-list-ref]').data('list-ref')}")
    AL.moveToPage list, pager.data("list-move-to-page")

  return
) jQuery, ActiveList
