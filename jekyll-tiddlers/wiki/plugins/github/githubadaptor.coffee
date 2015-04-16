return if not $tw.browser

HOME = do ->
  {protocol, host, pathname} = window.location
  "#{protocol}//#{host}#{pathname}"

LOGGER = new $tw.utils.Logger 'GithubAuth'

[$, Yaml, Octokat] = [
  '$:/library/jquery.js'
  '$:/library/js-yaml.js'
  '$:/library/octokat.js'
].map require


class OAuth
  STORAGE_KEY = 'OAUTH_TOKEN'
  GITHUB_AUTH = 'https://github.com/login/oauth/authorize'
  DEFAULT_AUTH = 'https://cerbero.herokuapp.com/authenticate/'

  constructor: (@wiki) ->
    @logger = LOGGER
    match = window.location.href.match /\?token=(.*)/
    if match
      @setToken match[1]
      window.location.href = HOME
    @config = window.GitHubConfig

  getUri: ->
    {client_id, scope, redirect_uri} = @config
    scope ?= 'public_repo'
    redirect_uri ?= DEFAULT_AUTH + '?' + $.param redirect_uri: HOME
    GITHUB_AUTH + '?' + $.param {client_id, scope, redirect_uri}


  getToken: ->
    localStorage.getItem STORAGE_KEY

  setToken: (token) ->
    localStorage.setItem STORAGE_KEY, token

  login: ->
    @logout()
    window.location.href = @getUri()

  logout: ->
    localStorage.clear()
    window.location.href = HOME

class GithubAdaptor

  constructor: (options) ->
    { @wiki } = options
    @config = window.GitHubConfig
    @logger = LOGGER
    @api = new Octokat token: (new OAuth @wiki).getToken()
    [org, repo] = @config.project.split '/'
    @repo = @api?.repos org, repo

  getTiddlerInfo: (tiddler) -> {}

  getStatus: (callback) ->
    @logger.log 'Getting status'
    @api.user.fetch (err, res) =>
      if err
        @logger.log 'Unauthorized'
        @api = null
        callback null, false, null
      else
        @logger.log 'Authorized'
        $tw.notifier.display "$:/language/Notifications/Github/Auth"
        callback null, true, res.login

  login: (username, password, callback) ->
    @api = new Octokat { username, password }
    @getStatus callback

  logout: (callback) ->
    @api = null
    localStorage.clear()

  getCsrfToken: ->
    regex = /^(?:.*; )?csrf_token=([^(;|$)]*)(?:;|$)/
    match = regex.exec(document.cookie)
    csrf = null
    if match and match.length == 2
      csrf = match[1]
    csrf

  getSkinnyTiddlers: (callback) ->
    $.getJSON "#{HOME}tiddlers.json", (tiddlers) =>
      callback null, tiddlers
    .fail (err) -> callback err.statusText

  saveTiddler: (tiddler, callback, info={}) ->
    title = tiddler.fields.title
    return unless @_checkFile title, callback
    content = btoa @_tiddlerFormat tiddler.fields
    file = @repo.contents "_tiddlers/#{title}.tid"
    file.fetch (err, res) =>
      if err
        message = "Create tiddler: #{title}"
        @_addFile file, callback, {message, content}
      else
        message = "Save tiddler: #{title}"
        @_addFile file, callback, {message, content, sha: res.sha}

  loadTiddler: (title, callback) ->
    filename = encodeURI encodeURIComponent title
    file = "tiddlers/#{filename}.json"
    $.getJSON file, (tiddler) =>
      callback null, tiddler
    .fail (err) =>
      @logger.log err
      callback err.statusText

  deleteTiddler: (title, callback, options) ->
    return unless @_checkFile title, callback
    file = @repo.contents "_tiddlers/#{title}.tid"
    file.fetch (err, res) =>
      @logger.log {err, res}
      if err then return callback err
      request =
        message: "Delete tiddler: #{title}"
        sha: res.sha
      file.remove request, (err, res) =>
        @logger.log {err, res}
        if err then return callback err
        callback null, null, res.sha

  _checkFile: (title, callback) ->
    unless @api
      msg = @wiki.getTiddler "$:/language/Notifications/Github/Unauth"
      callback(msg.text, null, null)
      return false
    for char in ['/', '\0']
      if char in title
        callback("''Invalid title''. It cannot contain \"/\" or \"\\0\".", null, null)
        return false
    return true

  _addFile: (file, callback, req) ->
    file.add req, (err, res) =>
      @logger.log {err, res}
      if err then return callback err
      callback null, null, res.sha

  _tiddlerFormat: (fields) ->
    text = ''
    tiddler = {}
    for field, value of fields
      if field is 'text'
        text = value
      else
        tiddler[field] = value
    tiddler.type ?= 'text/vnd.tiddlywiki'
    frontmatter = Yaml.dump tiddler
    "---\n#{frontmatter}---\n#{text}"



exports.GithubAdaptor = exports.adaptorClass = GithubAdaptor
exports.OAuth = OAuth
