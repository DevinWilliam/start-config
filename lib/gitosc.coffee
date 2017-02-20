LoginDialog = require './login-dialog'
CloneDialog = require './clone-dialog'
CreateDialog = require './create-dialog'
CommitDialog = require './commit-dialog'
CreateBranchDialog = require './create-branch-dialog'
SwitchBranchDialog = require './switch-branch-dialog'
ProgressDialog = require './progress-dialog'
DiffDialog = require './diff-dialog'

GitFile = require './git-file'
git = require './git'

{CompositeDisposable} = require 'atom'

noProjectFile = '无法确认当前编辑文件或当前编辑文件所属打开工程目录'
noGitClient = '未安装Git客户端错误'

module.exports = GitOSC =
  loginDialog: null
  cloneDialog: null
  createDialog: null
  commitDialog: null
  createBranchDialog: null
  switchBranchDialog: null
  progressDialog: null
  diffDialog: null

  subscriptions: null

  private_token: null

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    @createViews(state)

    @subscriptions.add atom.commands.add 'atom-workspace',
      'gitosc:clone-project': =>
        @clone()
      'gitosc:create-project': =>
        @create()
      'gitosc:commit-project': =>
        @commit()
      'gitosc:create-branch': =>
        @branch()
      'gitosc:switch-branch': =>
        @switch()
      'gitosc:compare-project': =>
        @compare()
      'gitosc:open-repository': ->
        if itemPath = getActivePath()
          GitFile.fromPath(itemPath).openRepository()
      'gitosc:open-issues': ->
        if itemPath = getActivePath()
          GitFile.fromPath(itemPath).openIssues()
      'gitosc:open-history': ->
        if itemPath = getActivePath()
          GitFile.fromPath(itemPath).history()

  deactivate: ->
    @subscriptions.dispose()

    @loginDialog?.deactivate()
    @loginDialog = null

    @cloneDialog?.deactivate()
    @cloneDialog = null

    @createDialog?.deactivate()
    @createDialog = null

    @commitDialog?.deactivate()
    @commitDialog = null

    @createBranchDialog?.deactivate()
    @createBranchDialog = null

    @switchBranchDialog?.deactivate()
    @switchBranchDialog = null

    @progressDialog?.deactivate()
    @progressDialog = null

    @diffDialog?.deactivate()
    @diffDialog = null

    return

  serialize: ->
    loginDialogState: @loginDialog?.serialize()
    cloneDialogState: @cloneDialog?.serialize()
    createDialogState: @createDialog?.serialize()
    commitDialogState: @commitDialog?.serialize()
    createBranchDialogState: @createBranchDialog?serialize()
    switchBranchDialogState: @switchBranchDialog?.serialize()
    progressDialogState: @progressDialog?.serialize()
    diffDialogState: @diffDialog?.serialize()
    return

  createViews: (state) ->
    unless @loginDialog?
      @loginDialog = new LoginDialog state.loginDialogState

    unless @cloneDialog?
      @cloneDialog = new CloneDialog state.cloneDialogState

    unless @createDialog?
      @createDialog = new CreateDialog state.createDialogState

    unless @commitDialog?
      @commitDialog = new CommitDialog state.commitDialogState

    unless @createBranchDialog?
      @createBranchDialog = new CreateBranchDialog state.createBranchDialogState

    unless @switchBranchDialog?
      @switchBranchDialog = new SwitchBranchDialog state.switchBranchDialogState

    unless @progressDialog?
      @progressDialog = new ProgressDialog state.progressDialogState

    unless @diffDialog?
      @diffDialog = new DiffDialog state.diffDialogState

    return

  clone: ->
    git.effective (err) =>
      if err
        atom.notifications.addWarning(noGitClient)
        return

      unless @private_token?
        @loginDialog.activate (username, password, @private_token) =>
          git.username = username
          git.password = password
          @cloneDialog.activate @private_token, (path_with_namespace, clone_dir, pro_name) =>
            @progressDialog.activate '克隆项目中...'
            git.clone path_with_namespace, clone_dir, pro_name, (err, pro_dir) =>
              unless err
                atom.project.addPath pro_dir
              @progressDialog.deactivate()

              if err
                atom.notifications.addWarning('克隆项目代码出错！')

      else
        @cloneDialog.activate @private_token, (path_with_namespace, clone_dir, pro_name) =>
          @progressDialog.activate '克隆项目中...'
          git.clone path_with_namespace, clone_dir, pro_name, (err, pro_dir) =>
            unless err
              atom.project.addPath pro_dir
            @progressDialog.deactivate()

            if err
              atom.notifications.addWarning('克隆项目代码出错！')

  create: ->
    git.effective (err) =>
      if err
        atom.notifications.addWarning(noGitClient)
        return

      unless @private_token?
        @loginDialog.activate (username, password, @private_token) =>
          git.username = username
          git.password = password
          @createDialog.activate @private_token, (pro_dir, pro_name, pro_description, pro_private) =>
            @progressDialog.activate '创建仓库中...'
            git.create @private_token, pro_dir, pro_name, pro_description, pro_private, (err) =>
              @progressDialog.deactivate()

              if err
                atom.notifications.addWarning('创建远程仓库失败！')
              else
                atom.project.addPath pro_dir

      else
        @createDialog.activate @private_token, (pro_dir, pro_name, pro_description, pro_private) =>
          @progressDialog.activate '创建仓库中...'
          git.create @private_token, pro_dir, pro_name, pro_description, pro_private, (err) =>
            @progressDialog.deactivate()

            if err
              atom.notifications.addWarning('创建远程仓库失败！')
            else
              atom.project.addPath pro_dir

  commit: ->
    git.effective (err) =>
      if err
        atom.notifications.addWarning(noGitClient)
        return

      projectPath = getActiveProjectPath()
      unless projectPath
        atom.notifications.addWarning(noProjectFile)
        return

      git.revise projectPath, (err, goon) =>
        if err
          atom.notifications.addWarning('发生错误，原因可能是当前工程属于未托管项目')
          return

        unless goon
          atom.notifications.addWarning('项目暂无修改，无需提交！')
          return

        git.getOSCRemote projectPath, (origin) =>
          unless origin
            atom.notifications.addWarning('当前项目不属于码云托管项目')
            return

          unless @private_token?
            @loginDialog.activate (username, password, @private_token) =>
              git.username = username
              git.password = password
              @commitDialog.activate projectPath, (pro_dir, msg) =>
                @progressDialog.activate '提交代码中...'
                git.commit pro_dir, msg, (err) =>
                  @progressDialog.deactivate()

                  if err
                    atom.notifications.addWarning('提交代码失败！')

          else
            @commitDialog.activate projectPath, (pro_dir, msg) =>
              @progressDialog.activate '提交代码中...'
              git.commit pro_dir, msg, (err) =>
                @progressDialog.deactivate()

                if err
                  atom.notifications.addWarning('提交代码失败！')

  branch: ->
    git.effective (err) =>
      if err
        atom.notifications.addWarning(noGitClient)
        return

      projectPath = getActiveProjectPath()
      if projectPath
        @createBranchDialog.activate projectPath, (err) ->
          unless err
            atom.notifications.addWarning('成功创建并切换分支！')
          else
            atom.notifications.addWarning('创建分支失败，原因不明。')
      else
        atom.notifications.addWarning(noProjectFile)

  switch: ->
    git.effective (err) =>
      if err
        atom.notifications.addWarning(noGitClient)
        return

      projectPath = getActiveProjectPath()
      if projectPath
        @switchBranchDialog.activate projectPath, (err) ->
          unless err
            atom.notifications.addWarning('切换分支成功！')
          else
            atom.notifications.addWarning('切换分支失败，原因不明。')
      else
        atom.notifications.addWarning(noProjectFile)

  compare: ->
    git.effective (err) =>
      if err
        atom.notifications.addWarning(noGitClient)
        return

      projectPath = getActiveProjectPath()
      if projectPath
        git.diff projectPath, (err, diffs) =>
          unless err
            if diffs.length > 0
              @diffDialog.activate diffs
            else
              atom.notifications.addWarning('项目暂无修改！')
            return
          atom.notifications.addWarning('无法查看修改！')
      else
        atom.notifications.addWarning(noProjectFile)

getActivePath = ->
  atom.workspace.getActivePaneItem()?.getPath?()

getActiveProjectPath = ->
  filePath = getActivePath()
  [rootDir] = atom.project.relativizePath(filePath)
  rootDir
