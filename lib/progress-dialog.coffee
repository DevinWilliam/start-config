Dialog = require './dialog'

module.exports =
class ProgressDialog extends Dialog
  @content: ->
    @div class: 'gitosc-dialog', =>
      @div class: 'heading', =>
        @strong '码云 -- 处理中'
      @div class: 'body', =>
        @label class: 'native-key-bindings', outlet: 'msg'
        @progress '处理中...'

  serialize: ->

  activate: (msg) ->
    @msg.text(msg)
    super
