{View} = require 'atom-space-pen-views'

module.exports =
class Dialog extends View
  panel: null

  activate: ->
    unless @panel?
      @addClass('active')
      @panel = atom.workspace.addModalPanel item: this
      @parent().css('top', '-40px')
    return

  deactivate: ->
    if @panel?
      @removeClass('active')
      @panel.destroy()
      @panel = null
    return

  cancel: ->
    @deactivate()
    return
