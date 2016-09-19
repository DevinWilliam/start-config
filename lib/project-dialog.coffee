Dialog = require './dialog'
path = require 'path'

module.exports =
class ProjectDialog extends Dialog
  callback: null

  @content: ->
    @div class: 'gitosc-dialog', =>
      @div class: 'heading', =>
        @i class: 'icon x clickable', click: 'cancel'
        @strong '码云 -- 项目选择'
      @div class: 'body', =>
        @label '当前项目'
        @select outlet: 'projectList'
      @div class: 'buttons', =>
        @button class: 'active', click: 'changeProject', =>
          @i class: 'icon icon-repo-pull'
          @span '确定'
        @button click: 'cancel', =>
          @i class: 'icon x'
          @span '取消'

  serialize: ->

  activate: (@callback) ->
    projectIndex = 0
    @projectList.empty()
    for dir in atom.project.getDirectories()
      option = document.createElement("option")
      option.value = projectIndex
      option.text = path.basename(path.resolve(dir.getPath()))
      @projectList.append(option)
      projectIndex = projectIndex + 1

    return super()

  changeProject: ->
    @deactivate()
    @callback(@projectList.val())
