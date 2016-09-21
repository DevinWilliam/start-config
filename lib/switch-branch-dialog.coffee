git = require 'git-promise'
Dialog = require './dialog'

module.exports =
class SwitchBranchDialog extends Dialog
  callback: null
  projectDir: null

  @content: ->
    @div class: 'gitosc-dialog', =>
      @div class: 'heading', =>
        @i class: 'icon x clickable', click: 'cancel'
        @strong '码云 -- 切换分支'
      @div class: 'body', =>
        @select outlet: 'branchList'
      @div class: 'buttons', =>
        @button class: 'active', click: 'switch', =>
          @i class: 'icon branch'
          @span '确定'
        @button click: 'cancel', =>
          @i class: 'icon x'
          @span '取消'

  serialize: ->

  activate: (@projectDir, @callback) ->
    @branchList.empty()
    git('git branch', {cwd: @projectDir}).then (stdout) =>
      branchCount = 0
      for branch in stdout.split('\n')
        if branch
          option = document.createElement("option")
          if branch[0] == '*'
            option.value = branch.slice(2)
          else
            option.value = branch
          option.text = branch
          @branchList.append(option)
          branchCount += 1

      if branchCount.length <= 1
        atom.notifications.addWarning('没有分支可切换！')
        return

      super

  switch: ->
    @deactivate()
    git 'git checkout ' + @branchList.val(), {cwd: @projectDir}
    .then (stdout) =>
      @callback(null)
    .fail (err) =>
      @callback(err)
