git = require 'git-promise'
Dialog = require './dialog'

module.exports =
class CreateBranchDialog extends Dialog
  callback: null
  projectDir: null

  @content: ->
    @div class: 'gitosc-dialog', =>
      @div class: 'heading', =>
        @i class: 'icon x clickable', click: 'cancel'
        @strong '码云 -- 创建分支'
      @div class: 'body', =>
        @label '当前分支'
        @input class: 'native-key-bindings', type: 'text', readonly: true, outlet: 'fromBranch'
        @label '新分支'
        @input class: 'native-key-bindings', type: 'text', outlet: 'toBranch'
        @label outlet: 'errmsg'
      @div class: 'buttons', =>
        @button class: 'active', click: 'branch', =>
          @i class: 'icon branch'
          @span '创建'
        @button click: 'cancel', =>
          @i class: 'icon x'
          @span '取消'

  activate: (@projectDir, @callback) ->
    @errmsg.val('')
    @fromBranch.val('')
    @toBranch.val('')

    git 'git branch', cwd: @projectDir
    .then (data) =>
      unless data
        throw new Error

      currentBranch = null
      for branch in data.split('\n')
        if branch
          if branch[0] == '*'
            currentBranch = branch.slice(2)
            break
      if currentBranch
        @fromBranch.val(currentBranch)
        super
      else
        throw new Error
    .fail (err) =>
      @callback(err)

  branch: ->
    unless @toBranch.val()
      @errmsg.val('请输入新建分支名称！')
      return
    git 'git branch', cwd: @projectDir
    .then (data) =>
      for branch in data.split('\n')
        if branch
          if branch[0] == '*'
            branch = branch.slice(2)
          if branch == @toBranch.val()
            @errmsg.val('新建分支名称与现有分支重名！')
            @toBranch.val('')
            throw new Error

      @deactivate()
      git 'git checkout -b ' + @toBranch.val(), cwd: @projectDir
      .then (data) =>
        @callback(null)
      .fail (err) =>
        @callback(err)
    .fail (err) =>
