Dialog = require './dialog'

module.exports =
class ConfirmDialog extends Dialog
  callback: null
  params: null

  @content: ->
    @div class: 'gitee-dialog active', =>
      @div class: 'heading', =>
        @i class: 'icon x clickable', click: 'cancel'
        @strong params.hdr
      @div class: 'body', =>
        @div params.msg
      @div class: 'buttons', =>
        @button class: 'active', click: 'confirm', =>
          @i class: 'icon check'
          @span '是'
        @button click: 'cancel', =>
          @i class: 'icon x'
          @span '否'

  serialize: ->

  activate: (@params, @callback) ->

  confirm: ->
    @deactivate()
    @callback()
    return
