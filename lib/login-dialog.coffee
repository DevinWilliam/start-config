axios = require 'axios'
Dialog = require './dialog'
fs = require 'fs'

module.exports =
class LoginDialog extends Dialog
  callback: null

  @content: ->
    @div class: 'gitee-dialog', =>
      @div class: 'heading', =>
        @i class: 'icon x clickable', click: 'cancel'
        @strong '码云 -- 登录'
      @div class: 'body', =>
        @label '邮箱'
        @input class: 'native-key-bindings', type: 'text', outlet: 'email'
        @label '密码'
        @input class: 'native-key-bindings', type: 'password', outlet: 'password'
        @label class: 'error', outlet: 'errmsg'
      @div class: 'buttons', =>
        @button class: 'active', click: 'login', =>
          @i class: 'icon tag'
          @span '登录'
        @button click: 'cancel', =>
          @i class: 'icon x'
          @span '取消'

  serialize: ->

  activate: (@callback) ->
    @errmsg.text('')
    @password.val('')
    fs.readFile 'gitee_email_cache', (err, data) =>
      unless err
        @email.val(data)
    super

  login: ->
    password = @password.val()
    axios.post 'https://gitee.com/api/v3/session', 'email=' + @email.val() + '&password=' + password
      .then (res) =>
        fs.writeFile 'gitee_email_cache', @email.val(), (err) ->
        @deactivate()
        @callback(res.data.username, password, res.data.private_token)
      .catch (err) =>
        @errmsg.text('邮箱或密码输入不正确！')
        @password.val('')
