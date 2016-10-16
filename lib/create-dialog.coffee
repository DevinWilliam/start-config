path = require 'path'

axios = require 'axios'
Dialog = require './dialog'

remote = require('electron').remote
dialog = remote.require('electron').dialog

module.exports =
class CreateDialog extends Dialog
  callback: null
  exist_pro_list: []

  @content: ->
    @div class: 'gitosc-dialog', =>
      @div class: 'heading', =>
        @i class: 'icon x clickable', click: 'cancel'
        @strong '码云 -- 创建项目'
      @div class: 'body', =>
#        @label '项目目录'
#        @select outlet: 'projectList'
        @label '项目目录'
        @input class: 'native-key-bindings', type: 'text', readonly: true, outlet: 'pro_dir', click: 'choose_dir'
        @label '项目名'
        @input class: 'native-key-bindings', outlet: 'pro_name'
        @label '项目介绍(可选)'
        @textarea class: 'native-key-bindings', outlet: 'pro_description'
        @input class: 'native-key-bindings checkbox', type: 'checkbox', outlet: 'pro_private'
        @label '私有项目？'
        @label class: 'error', outlet: 'errmsg'
      @div class: 'buttons', =>
        @button class: 'active', click: 'create', =>
          @i class: 'icon tag'
          @span '创建'
        @button click: 'cancel', =>
          @i class: 'icon x'
          @span '取消'

  serialize: ->

  activate: (private_token, @callback) ->
    @pro_dir.val('')
    @errmsg.text('')
    @pro_name.val('')
    @pro_description.val('')
    @pro_private.attr("checked", false)
#    @projectList.empty()
#    for dir in atom.project.getDirectories()
#      option = document.createElement("option")
#      option.value = option.text = path.resolve(dir.getPath())
#      @projectList.append(option)

#    if @projectList.length == 0
#      atom.notifications.addWarning('没有可供提交的工程！')
#      return

    super

    axios.get 'https://git.oschina.net/api/v3/projects?page=1&per_page=1000&private_token=' + private_token
    .then (res) =>
      @exist_pro_list = []
      res.data.map (pro) =>
        @exist_pro_list.push(pro.name)

  create: ->
#    unless @projectList.val()
#      @errmsg.text('请选择提交的项目！')
#      return
    unless @pro_dir.val()
      @errmsg.text('请选择要托管的项目目录')
    unless @pro_name.val()
      @errmsg.text('请输入项目名称')
      return
    unless @pro_description.val()
      @errmsg.text('请输入项目描述')
      return
    myRe = /^[a-zA-Z][\w\-\.]*$/
    unless myRe.test(@pro_name.val())
      @errmsg.text('项目名 只允许字母、数字或者下划线(_)、中划线(-)、英文句号(.)，必须以字母开头')
      return

    for exist_pro_name in @exist_pro_list
      if exist_pro_name == @pro_name.val()
        @errmsg.text('项目' + @pro_name.val() + '已经存在!')
        return

    @deactivate()
#    @callback(@projectList.val(), @pro_name.val(), @pro_description.val(), @pro_private.val())
    @callback(@pro_dir.val(), @pro_name.val(), @pro_description.val(), @pro_private.is(':checked'))

  choose_dir: ->
    dialog.showOpenDialog {properties:['openDirectory']}, (dirs) =>
      if dirs
        @pro_dir.val(dirs[0])
        dir_seps = dirs[0].split(path.sep)
        @pro_name.val(dir_seps[dir_seps.length-1])
