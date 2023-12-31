git = require 'git-promise'
axios = require 'axios'

path = require 'path'

module.exports = Git =
  username: null
  password: null

  getBranches: (pro_dir, callback) ->
    git 'git branch', cwd: @pro_dir
    .then (data) ->
      branches = new Array()
      if data
        for branch in data.split('\n')
          if branch
            if branch[0] == '*'
              branches.push(branch.slice(2))
            else
              branches.push(branch)
      else
        branches.push('master')
      callback(branches)
    .fail (err) ->
      callback(null)

  getCurrentBranch: (pro_dir, callback) ->
    git 'git branch', cwd: pro_dir
    .then (data) ->
      if data
        for branch in data.split('\n')
          if branch
            if branch[0] == '*'
              callback(branch.slice(2))
              break
      else
        callback('master')
      return
    .fail (err) ->
      callback(null)

  getOSCRemote: (pro_dir, callback) ->
    git 'git remote -v', cwd: pro_dir
    .then (data) ->
      origin = data.match(/origin\s(.+)\s\(push\)/)[1]
      if origin && origin.indexOf('https://gitee.com/') == 0
        callback(origin)
      else if origin && origin.indexOf('git@gitee.com:') == 0
        origin = origin.replace('git@gitee.com:', 'https://gitee.com/')
        callback(origin)
      else
        callback(null)
    .fail (err) ->
      callback(null)

  effective: (callback) ->
    git 'git --version'
    .then (data) ->
      callback(null)
      return
    .fail (err) ->
      callback(err)

  revise: (pro_dir, callback) ->
    git 'git status', cwd: pro_dir
    .then (stdout) ->
      if stdout.indexOf('nothing to commit, working tree clean') > 0
        callback(null, false)
      else
        callback(null, true)
    .fail (err) ->
      callback(err)

  clone: (path_with_namespace, clone_dir, pro_name, callback) ->
    username = @username
    password = @password
    clone_url = 'https://gitee.com/' + path_with_namespace
    pro_dir = path.join clone_dir, pro_name
    cmd = 'clone https://' + username + ':' + password + '@' + clone_url.split('//')[1] + ' ' + pro_name
    git cmd, cwd: clone_dir
    .then () ->
      git 'git remote rm origin', cwd: pro_dir
    .then () ->
      callback(null, pro_dir)
    .fail (err) ->
      callback(err, null)
    .finally () ->
      git 'git remote add origin https://gitee.com/' + path_with_namespace, cwd: pro_dir
      return

  initial: (pro_dir, callback) ->
    git 'git init', cwd: pro_dir
    .then () ->
      git 'git add -A', cwd: pro_dir
    .then () ->
      git 'git commit -m "初始化项目"', cwd: pro_dir
    .then () ->
      callback(null)
    .fail (err) ->
      callback(err)

  create: (private_token, pro_dir, pro_name, pro_description, pro_private, callback) ->
    username = @username
    password = @password
    @initial pro_dir, (err) ->
      arg = 'name=' + pro_name + '&description=' + pro_description + '&private=' + if pro_private then '1' else '0'
      axios.post 'https://gitee.com/api/v3/projects?private_token=' + private_token, arg
      .then (res) ->
        remote_url = 'https://' + username + ':' + password + '@gitee.com/' + username + '/' + pro_name
        git 'git push -u ' + remote_url + ' master', cwd: pro_dir
        .then () ->
          callback(null)
        .fail (err) ->
          # 创建项目目录为空时首次提交会失败，这里我们当成功处理
          callback(null)
        .finally () ->
          git 'git remote rm origin', cwd: pro_dir
          .finally () ->
            git 'git remote add origin https://gitee.com/' + username + '/' + pro_name, cwd: pro_dir
          return
      .fail (err) ->
        callback(err)

  commit: (pro_dir, message, callback) ->
    username = @username
    password = @password
    getOSCRemote = @getOSCRemote
    @getCurrentBranch pro_dir, (cur_branch) ->
      if cur_branch
        getOSCRemote pro_dir, (origin) ->
          if origin
            git 'git add -A', cwd: pro_dir
            .then () ->
              git 'git commit -m "' + message + '"', cwd: pro_dir
            .then () ->
              remote_url = 'https://' + username + ':' + password + '@' + origin.split('//')[1]
              git 'git push ' + remote_url + ' ' + cur_branch, cwd: pro_dir
            .then () ->
              callback(null)
            .fail (err) ->
              callback(err)
          else
            callback(new Error('这不是码云项目'))
      else
        callback(new Error('获取当前分支出错'))

  diff: (pro_dir, callback) ->
    git 'git --no-pager diff', cwd: pro_dir
    .then (data) ->
      callback(null, parseDiff(data))
    .fail (err) ->
      callback(err, null)

parseDiff = (data) ->
  diffs = []
  diff = {}
  for line in data.split('\n') when line.length
    switch
      when /^diff --git /.test(line)
        diff =
          lines: []
          added: 0
          removed: 0
        diff['diff'] = line.replace(/^diff --git /, '')
        diffs.push diff
      when /^index /.test(line)
        diff['index'] = line.replace(/^index /, '')
      when /^--- /.test(line)
        diff['---'] = line.replace(/^--- [a|b]\//, '')
      when /^\+\+\+ /.test(line)
        diff['+++'] = line.replace(/^\+\+\+ [a|b]\//, '')
      else
        diff['lines'].push line
        diff['added']++ if /^\+/.test(line)
        diff['removed']++ if /^-/.test(line)

  return diffs
