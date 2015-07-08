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
        
        # list.html data
        selection = list.prop('selection')
        if selection?
          for id in selection
            list.find("input[data-list-selector='#{id}']")
              .attr('checked', 'checked')
              .closest('tr').addClass('selected')
          AL.checkGlobalButtons list
        list.trigger('page:change')
        $(document).trigger('list:page:change')
        true

    false


  # Select a row of "many" buttons
  AL.select = (checkbox) ->
    list = checkbox.closest('*[data-list-source]')
    row = checkbox.closest('tr')
    if list.prop('selection')?
      selection = list.prop('selection')
    else
      selection = []
    key = checkbox.data('list-selector')
    index = selection.indexOf(key)
    if checkbox.is ":checked"
      if index < 0 
        selection.push(key)
      row.addClass("selected")
    else
      if index >= 0 
        selection.splice(index, 1)
      row.removeClass("selected")
    list.prop('selection', selection)
    AL.checkGlobalButtons list


  # Hide/show needed global buttons
  AL.checkGlobalButtons = (list) -> 
    selection = list.prop('selection')
    list_id = list.attr('id')
    actions = $("*[data-list-ref='#{list_id}']")
    if selection.length > 0
      actions.find("*[data-list-actioner='none']:visible").hide()
      actions.find("*[data-list-actioner='none']:visible").hide()
      actions.find("*[data-list-actioner='many']:hidden").show()
    else
      actions.find("*[data-list-actioner='none']:hidden").show()
      actions.find("*[data-list-actioner='many']:visible").hide()
    actions.find("*[data-list-actioner='many']").each (index) ->
      button = $(this)
      unless button.prop('hrefPattern')?
        button.prop('hrefPattern', button.attr('href'))
      pattern = button.prop('hrefPattern')
      url = pattern.replace(encodeURIComponent("##IDS##"), selection.join(','), 'g')
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
  $(document).on "click", "*[data-list-source] input[data-list-selector]", (event) ->
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
