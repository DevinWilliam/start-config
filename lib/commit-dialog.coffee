path = require 'path'
git = require 'git-promise'

Dialog = require './dialog'

module.exports =
class CommitDialog extends Dialog
  callback: null
  projectDir: null

  @content: ->
    @div class: 'gitosc-dialog', =>
      @div class: 'heading', =>
        @i class: 'icon x clickable', click: 'cancel'
        @strong '码云 -- 提交'
      @div class: 'body', =>
#        @label '提交项目'
#        @select outlet: 'projectList'
        @label '提交注释'
        @textarea class: 'native-key-bindings', outlet: 'msg', keyUp: 'colorLength'
        @label class: 'error', outlet: 'errmsg'
      @div class: 'buttons', =>
        @button class: 'active', click: 'commit', =>
          @i class: 'icon commit'
          @span '提交'
        @button click: 'cancel', =>
          @i class: 'icon x'
          @span '取消'

  serialize: ->

  activate: (@projectDir, @callback) ->
    @msg.val('')
    @errmsg.text('')
#    @projectList.empty()
#    for dir in atom.project.getDirectories()
#      resolvePath = path.resolve(dir.getPath())
#      git('git remote -v', {cwd: resolvePath}).then (stdout) =>
#        if stdout.match /gitosc\s(.+)\s\(push\)/
#          option = document.createElement("option")
#          option.value = resolvePath
#          option.text = path.basename(resolvePath)
#          @projectList.append(option)

#    if @projectList.length == 0
#      atom.notifications.addWarning('没有项目可供提交！')
#      return

    super

  colorLength: ->
    too_long = false
    for line, i in @msg.val().split("\n")
      if (i == 0 && line.length > 50) || (i > 0 && line.length > 80)
        too_long = true
        break

    if too_long
      @msg.addClass('over-fifty')
    else
      @msg.removeClass('over-fifty')
    return

#  getMessage: ->
#    @msg.val()

  commit: ->
#    unless @projectList.val()
#      @errmsg.text('请选择提交的项目！')
#      return
    unless @msg.val()
      @errmsg.text('请输入提交注释！')
      return
    @deactivate()
#    @callback(@projectList.val(), @msg.val())
    @callback(@projectDir, @msg.val())
