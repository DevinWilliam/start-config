{View, ScrollView} = require 'atom-space-pen-views'
Dialog = require './dialog'

class DiffLine extends View
  @content: (line) ->
    @div class: "line #{line.type}", =>
      @pre class: "lineno #{unless line.lineno then 'invisible' else ''}", line.lineno
      @pre outlet: 'linetext', line.text

  initialize: (params) ->
    if params.type == 'heading' then @linetext.click(-> atom.workspace.open(params.text))

fmtNum = (num) ->
  return "     #{num or ''} ".slice(-6)

class DiffView extends ScrollView
  @content: ->
    @div class: 'gitosc-diff'

  getTitle: ->
    return 'gitosc-diff'

  clearAll: ->
    @find('>.line').remove()
    return

  addAll: (diffs) ->
    @clearAll()

    diffs.forEach (diff) =>
      if (file = diff['+++']) is '+++ /dev/null'
        file = diff['---']

      @append new DiffLine(type: 'heading', text: file)

      noa = 0
      nob = 0

      diff.lines.forEach (line) =>
        klass = ''
        lineno = undefined

        if /^@@ /.test(line)
          # @@ -100,11 +100,13 @@
          [atstart, linea, lineb, atend] = line.replace(/-|\+/g, '').split(' ')
          noa = parseInt(linea, 10)
          nob = parseInt(lineb, 10)
          klass = 'subtle'

        else
          lineno = "#{fmtNum noa}#{fmtNum nob}"

          if /^-/.test(line)
            klass = 'red'
            lineno = "#{fmtNum noa}#{fmtNum 0}"
            noa++
          else if /^\+/.test(line)
            klass = 'green'
            lineno = "#{fmtNum 0}#{fmtNum nob}"
            nob++
          else
            noa++
            nob++

        @append new DiffLine(type: klass, text: line, lineno: lineno)

        return
      return
    return

module.exports =
class DiffDialog extends Dialog
  @content: ->
    @div class: 'gitosc-dialog', =>
      @div class: 'heading', =>
        @i class: 'icon x clickable', click: 'cancel'
        @strong '码云 -- 查看修改'
      @div class: 'body', =>
        @subview 'diffView', new DiffView()
      @div class: 'buttons', =>
        @button class: 'active', click: 'cancel', =>
          @i class: 'icon tag'
          @span '确定'

  serialize: ->

  activate: (diffs) ->
    @diffView.addAll(diffs)
    super
