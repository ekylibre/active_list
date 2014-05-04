ActiveList = {}

(($, AL) ->
  "use strict"
  
  # Main function which reload table with specified data parameters
  AL.refresh = (element, options) ->
    list = element.closest("div[data-list-source]")
    table = element.find("table[data-current-page]").first()
    parameters =
      sort:     table.data("list-sort-by")
      dir:      table.data("list-sort-dir")
      page:     table.data("list-current-page")
      per_page: table.data("list-page-size")
      only:     "content"

    $.extend parameters, options
    url = list.data("list-source")
    $.ajax url,
      data: parameters
      dataType: "html"
      success: (data, status, request) ->
        list.html data
        selection = list.prop('selection')
        if selection?
          for id in selection
            list.find("input[data-list-selector='#{id}']")
              .attr('checked', 'checked')
              .closest('tr').addClass('selected')
        true

    false

  AL.moveToPage = (element, page) ->
    page_attr = undefined
    # element = $(element);
    page = element.data("list-move-to-page") if !page? or page is ""
    alert "Cannot define which page to load: " + page if !page? or page is ""
    if isNaN(page)
      page_attr = page
      page = element.attr(page_attr)
      alert "Cannot define which page to load with attribute " + page_attr + ": " + page  if isNaN(page)
    AL.refresh element,
      page: page

    false

  
  # Sort by one column
  $(document).on "click", "div[data-list-source] th[data-list-column][data-list-column-sort]", (event) ->
    sorter = $(this)
    AL.refresh sorter,
      sort: sorter.data("list-column")
      dir:  sorter.data("list-column-sort")

    false

  
  # Change number of item per page
  $(document).on "click", "div[data-list-source] li[data-list-change-page-size]", (event) ->
    sizer = $(this)
    per_page = sizer.data("list-change-page-size")
    if isNaN(per_page)
      alert "@list-change-page-size attribute is not a number: " + per_page
    else
      AL.refresh sizer,
        per_page: per_page

    false

  
  # Toggle visibility of a column
  $(document).on "click", "div[data-list-source] li[data-list-toggle-column]", (event) ->
    element = $(this)
    visibility = ""
    columnId = element.data("list-toggle-column")
    list = element.closest("div[data-list-source]")
    column = list.find("th[data-list-column=\"" + columnId + "\"]")
    
    #$('#'+columnId);
    className = column.data("list-column-cells")
    className = columnId  if className is null
    search = "." + className
    if column.hasClass("hidden")
      $(search).removeClass "hidden"
      column.removeClass "hidden"
      element.removeClass "unchecked"
      element.addClass "checked"
      visibility = "shown"
    else
      $(search).addClass "hidden"
      column.addClass "hidden"
      element.removeClass "checked"
      element.addClass "unchecked"
      visibility = "hidden"
    url = list.data("list-source")
    $.ajax url,
      dataType: "html"
      data:
        visibility: visibility
        column: columnId

    false

  # Select row
  $(document).on "click", "div[data-list-source] input[data-list-selector]", (event) ->
    element = $(this)
    list = element.closest('div[data-list-source]')
    row = element.closest('tr')
    if list.prop('selection')?
      selection = list.prop('selection')
    else
      selection = []
    key = element.data('list-selector')
    index = selection.indexOf(key)
    if element.is ":checked"
      if index < 0 
        selection.push(key)
      row.addClass("selected")
    else
      if index >= 0 
        selection.splice(index, 1)
      row.removeClass("selected")
    list.prop('selection', selection)
    true
  
  # Change page of table on link clicks
  $(document).on "click", "div[data-list-source] a[data-list-move-to-page]", (event) ->
    AL.moveToPage $(this)
    false

  
  # Change page of table on input changes
  $(document).on "change", "div[data-list-source] input[data-list-move-to-page]", (event) ->
    AL.moveToPage $(this)
    false

  
  # Adds title attribute based on link name
  $(document).on "hover", "div[data-list-source] tbody tr td.act a", (event) ->
    element = $(this)
    title = element.attr("title")
    element.attr "title", element.html() unless title?
    return

  return
) jQuery, ActiveList
