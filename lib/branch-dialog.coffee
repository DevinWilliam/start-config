git = require 'git-promise'
Dialog = require './dialog'

module.exports =
class BranchDialog extends Dialog
  callback: null
  projectDir: null

  @content: ->
    @div class: 'gitosc-dialog', =>
      @div class: 'heading', =>
        @i class: 'icon x clickable', click: 'cancel'
        @strong '切换分支'
      @div class: 'body', =>
        @select outlet: 'branchList'
      @div class: 'buttons', =>
        @button class: 'active', click: 'branch', =>
          @i class: 'icon branch'
          @span '确定'
        @button click: 'cancel', =>
          @i class: 'icon x'
          @span '取消'

  serialize: ->

  activate: (@projectDir, @callback) ->
    @branchList.empty()
    git('git branch', {cwd: @projectDir}).then (stdout) =>
      for branch in stdout.split('\n')
        if branch
          option = document.createElement("option")
          if branch[0] == '*'
            option.value = branch.slice(2)
          else
            option.value = branch
          option.text = branch
          @branchList.append(option)

    if @branchList.length <= 1
      atom.notifications.addWarning('没有分支可切换！')
      return

    super

  branch: ->
    @deactivate()
    git('git checkout ' + @branchList.val(), {cwd: @projectDir}).then (stdout) =>
      @callback()
    return
