class TentStatus.Helpers.InputSelection
  constructor: (@el) ->
    @start = @calculateStart()
    @end = @calculateEnd()

  calculateStart: =>
    if @el.createTextRange
      r = document.selection.createRange().duplicate()
      r.moveEnd('character', @el.value.length)
      return @el.value.length if r.text == ''
      return @el.value.lastIndexOf(r.text)
    else
      return @el.selectionStart

  calculateEnd: =>
    if @el.createTextRange
      r = document.selection.createRange().duplicate()
      r.moveStart('character', -@el.value.length)
      return r.text.length
    else
      return @el.selectionEnd

  setSelectionRange: (start, end) =>
    if @el.createTextRange
      selRange = @el.createTextRange()
      selRange.collapse(true)
      selRange.moveStart('character', start)
      selRange.moveEnd('character', end)
      selRange.select()
    else if @el.setSelectionRange
      @el.setSelectionRange(start, end)
    else if @el.selectionStart
      @el.selectionStart = start
      @el.selectionEnd = end
    @el.focus()
