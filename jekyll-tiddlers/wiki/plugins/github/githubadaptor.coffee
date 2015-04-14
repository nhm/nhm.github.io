return if not $tw.browser

HOME = do ->
  {protocol, host, pathname} = window.location
  "#{protocol}//#{host}#{pathname}"

LOGGER = new $tw.utils.Logger 'GithubAuth'

CONFIG_TIDDLER = '$:/config/github'

jQuery = require('$:/library/jquery.js')
Yaml = require('$:/library/js-yaml.js')
Octokat = require('$:/library/octokat.js')


class OAuth

  STORAGE_KEY = 'OAUTH_TOKEN'

  constructor: (@wiki) ->
    @logger = LOGGER
    match = window.location.href.match /\?token=(.*)/
    if match
      @setToken match[1]
      console.log @getToken()
      window.location.href = HOME
    @config = @wiki.getTiddler(CONFIG_TIDDLER).fields

  getUri: ->
    params =
      client_id: @config.client_id
      scope: @config.scope or 'public_repo'
      redirect_uri: @config.redirect_uri or  "https://cerbero.herokuapp.com/authenticate/?redirect_uri=#{HOME}"
    console.log(params)
    'https://github.com/login/oauth/authorize?' + jQuery.param params


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
    @config = @wiki.getTiddler(CONFIG_TIDDLER).fields
    @logger = LOGGER
    @api = new Octokat token: (new OAuth @wiki).getToken()
    [org, repo] = @config.repo.split '/'
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
    jQuery.getJSON "#{HOME}tiddlers.json", (tiddlers) =>
      callback null, tiddlers
    .fail (err) -> callback err.statusText


  saveTiddler: (tiddler, callback, info={}) ->
    return callback('Unauthorized', null, null) unless @api

    title = tiddler.fields.title
    content = btoa @tiddlerFormat tiddler.fields
    filename = Title.encode title
    file = @repo.contents "_tiddlers/#{filename}.tid"

    save = (req) =>
      file.add req, (err, res) =>
        @logger.log {err, res}
        if err then return callback err
        callback null, null, res.sha

    file.fetch (err, res) =>
      if err?.statusCode is 404
        message = "Create tiddler: #{title}"
        save {message, content}
      else if err
        return callback err
      else
        message: "Save tiddler: #{title}"
        save {message, content, sha: res.sha}

  loadTiddler: (title, callback) ->
    filename = Title.encode title
    file = "tiddlers/#{filename}.json"
    jQuery.getJSON file, (tiddler) ->
      callback null, tiddler
    .fail (err) -> callback err.statusText

  deleteTiddler: (title, callback, options) ->
    return callback('Unauthorized', null, null) unless @api
    filename = Title.encode title
    file = @repo.contents "_tiddlers/#{filename}.tid"
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


  tiddlerFormat: (fields) ->
    {text} = fields.text
    delete fields.text
    fields.type ?= 'text/vnd.tiddlywiki'
    frontmatter = Yaml.dump fields
    "---\n#{frontmatter}---\n#{text}"


class Title
  ILEGAL_CHARS = ['%', '/', '\0']

  @encode = (title) ->
    for from in ILEGAL_CHARS
      to = encodeURIComponent from
      title = title.replace(new RegExp(from, 'g'), to)
    title

  @decode = (title) ->
    for to in ILEGAL_CHARS
      from = encodeURIComponent to
      title = title.replace(new RegExp(from, 'g'), to)
    title


exports.adaptorClass = GithubAdaptor
exports.OAuth = OAuth
