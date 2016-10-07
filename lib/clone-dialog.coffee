axios = require 'axios'
Dialog = require './dialog'

remote = require('electron').remote
dialog = remote.require('electron').dialog

fs = require 'fs'
path = require 'path'

module.exports =
class CloneDialog extends Dialog
  callback: null

  @content: ->
    @div class: 'gitosc-dialog', =>
      @div class: 'heading', =>
        @i class: 'icon x clickable', click: 'cancel'
        @strong '码云 -- 拉取项目'
      @div class: 'body', =>
        @label '项目'
#        @select class: 'native-key-bindings', outlet: 'projectList'
        @div class: 'selectbox', =>
          @select change: 'choose_pro', outlet: 'pro_list'
          @input class: 'native-key-bindings', outlet: 'pro'
        @label '目录'
        @input class: 'native-key-bindings', type: 'text', readonly: true, outlet: 'cloneDir', click: 'choose_dir'
        @label class: 'error', outlet: 'errmsg'
      @div class: 'buttons', =>
        @button class: 'active', click: 'clone', =>
          @i class: 'icon tag'
          @span '拉取'
        @button click: 'cancel', =>
          @i class: 'icon x'
          @span '取消'

  serialize: ->

  activate: (private_token, @callback) ->
    @errmsg.text('')
    axios.get 'https://git.oschina.net/api/v3/projects?page=1&per_page=1000&private_token=' + private_token
      .then (res) =>
#        @projectList.empty()
        @pro_list.empty()
        proCount = 0
        res.data.map (pro) =>
#          @projectList.append("<option value='#{pro.path_with_namespace}'>#{pro.name}</option>")
          @pro_list.append("<option value='#{pro.path_with_namespace}'>#{pro.path_with_namespace}</option>")
          proCount += 1
#        if @projectList.length > 0
        if proCount > 0
          @choose_pro()
          super
        else
          atom.notifications.addWarning('没有可供获取的项目！')
      .catch (err) =>
        atom.notifications.addWarning('获取项目列表失败！')

  clone: ->
#    unless @projectList.val()
#      @errmsg.text('请选择要拉取的项目！')
#      return
    pro_name = @pro.val()
    unless pro_name
      @errmsg.text('请输入或选择要拉取的项目！')
      return
    path_with_namespace = null
    for pro in @pro_list.children('option')
      if pro_name == pro.text
        path_with_namespace = pro.value
    unless path_with_namespace
      @errmsg.text('无效的项目名称！')
      return
    unless @cloneDir.val()
      @errmsg.text('请选择项目保存目录！')
      return
    try
      pro_dir_name = path_with_namespace.split('/')[1]
      stat = fs.statSync path.join @cloneDir.val(), pro_dir_name
      if stat.isDirectory()
        @errmsg.text('项目目录已经存在！')
        return
    catch error
    @deactivate()
#    @callback(@projectList.val(), @cloneDir.val())
    @callback(path_with_namespace, @cloneDir.val())

  choose_pro: ->
    for pro in @pro_list.children('option')
      if pro.selected
        @pro.val(pro.text)

  choose_dir: ->
    dialog.showOpenDialog {properties:['openDirectory']}, (dirs) =>
      if dirs
        @cloneDir.val(dirs[0])
