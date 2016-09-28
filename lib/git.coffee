git = require 'git-promise'
axios = require 'axios'

module.exports = Git =
  username: null
  password: null

  getBranches: (pro_dir, callback) ->
    git 'git branch', cwd: @pro_dir
    .then (data) ->
      branches = new Array()
      for branch in data.split('\n')
        if branch
          if branch[0] == '*'
            branches.push(branch.slice(2))
          else
            branches.push(branch)
      callback(branches)
    .fail (err) ->
      callback(null)

  getCurrentBranch: (pro_dir, callback) ->
    git 'git branch', cwd: pro_dir
    .then (data) ->
      for branch in data.split('\n')
        if branch
          if branch[0] == '*'
            callback(branch.slice(2))
            break
    .fail (err) ->
      callback(null)

  effective: (callback) ->
    git 'git --version'
    .then (data) ->
      callback(null)
    .fail (err) ->
      callback(err)

  clone: (path_with_namespace, clone_dir, callback) ->
    username = @username
    password = @password
    clone_url = 'https://git.oschina.net/' + path_with_namespace
    pro_dir = clone_dir + path_with_namespace.split('/')[1]
    cmd = 'clone https://' + username + ':' + password + '@' + clone_url.split('//')[1]
    git cmd, cwd: clone_dir
    .then () ->
      git 'git remote rm origin', cwd: pro_dir
    .then () ->
      callback(null, pro_dir)
    .fail (err) ->
      callback(err, null)
    .finally () ->
      git 'git remote add origin https://git.oschina.net/' + path_with_namespace, cwd: pro_dir
      git 'git remote add gitosc https://git.oschina.net/' + path_with_namespace, cwd: pro_dir
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
      axios.post 'https://git.oschina.net/api/v3/projects?private_token=' + private_token, arg
      .then (res) ->
        cmd = 'git remote add temp123 https://' + username + ':' + password + '@git.oschina.net/' + username + '/' + pro_name
        git cmd, cwd: pro_dir
        .then () ->
          git 'git push -u temp123 master', cwd: pro_dir
        .then () ->
          git 'git remote rm temp123', cwd: pro_dir
        .then () ->
          callback(null)
        .fail (err) ->
          callback(err)
        .finally () ->
          git 'git remote add origin https://git.oschina.net/' + username + '/' + pro_name, cwd: pro_dir
          git 'git remote add gitosc https://git.oschina.net/' + username + '/' + pro_name, cwd: pro_dir
          return
      .catch (err) ->
        callback(err)

  commit: (pro_dir, message, callback) ->
    username = @username
    password = @password
    @getCurrentBranch pro_dir, (cur_branch) ->
      if cur_branch
        git 'git remote -v', cwd: pro_dir
        .then (data) ->
          origin = data.match(/gitosc\s(.+)\s\(push\)/)[1]
          if origin
            cmd = 'git remote add temp123 https://' + username + ':' + password + '@' + origin.split('//')[1]
            git cmd, cwd: pro_dir
          else
            throw new Error('这不是码云项目')
        .then () ->
          git 'git add -A', cwd: pro_dir
        .then () ->
          git 'git commit -m "' + message + '"', cwd: pro_dir
        .then () ->
          git 'git push temp123 ' + cur_branch, cwd: pro_dir
        .then () ->
          callback(null)
        .fail (err) ->
          callback(err)
        .finally () ->
          git 'git remote rm temp123', cwd: pro_dir
          return
      else
        callback('获取当前分支出错')

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
