fetch = require 'node-fetch'
CSON = require 'season'
_ = require 'lodash'

module.exports =
class Shiina
  API_URL: 'https://api.chatwork.com/v1'
  GITHUB_API_URL: 'https://api.github.com'
  options: null
  previousCommitFetch: null
  previousCommitFetch: null
  
  constructor: ->
    API_TOKEN = @getConfig().API_TOKEN
    @options =
      headers:
        'X-ChatWorkToken': API_TOKEN
        
    @previousCommitFetch = @getConfigItem 'previousCommitFetch'
    unless @previousCommitFetch then @updateDate
    
  updateDate: (name) ->
    dateStr = (new Date()).toISOString()
    switch name
      when 'fetch-commits'
        @previousCommitFetch = dateStr
        @saveConfigItem 'previousCommitFetch', dateStr
        
  saveConfig: (name, data) ->
    CSON.writeFile name + '.cson', data, (err) ->
      console.log err if err?

  saveConfigItem: (name, value) ->
    data = @getConfig()
    data[name] = value
    @saveConfig 'config', data

  getConfigItem: (name) ->
    data = @getConfig()
    return data[name]
      
  fetchRooms: ->
    options = @getOptions
      method: 'get'
    api = 'rooms'
    console.log options
    fetch(@API_URL + "/#{api}" , options)
      .then (res) =>
        res.json()
      .then (json) =>
        @saveConfig api, json
      
  getOptions: ({method, headers, body, type} = {}) ->
    opt = {method}
    
    if headers is undefined
      opt.headers = {}
    else if headers isnt null
      opt.headers = headers
      
    if body is undefined
      opt.body = {}
    else if body isnt null
      opt.body = body     
      
    if type? && type is 'github'
      return opt 
    else
      _.merge opt, @options
    
  say: (roomid, message) ->
    messageData = 'body=' + encodeURIComponent(message)
    
    options = @getOptions
      method: 'post'
      body: messageData 
      headers:
        'Content-Type': 'application/x-www-form-urlencoded'
        'Content-Length': messageData.length
      
    fetch(@API_URL + "/rooms/#{roomid}/messages", options)
      .then (res) ->
        res.json()
      .then (json) ->
        console.log json
      .catch (err) ->
        console.log err
        
  getOrgRepos: (org = '') ->
    URL = "#{@getGithubApiUrl(true)}orgs/#{org}/repos"
    
    options = @getOptions
      method: 'get'
      type: 'github'
      
    fetch(URL, options)
      .then (res) =>
        res.json()
      .then (json) =>
        console.log json
        
  fetchCommits: (owner, repo) ->
    param = (if @previousCommitFetch then "since=#{@previousCommitFetch}" else '')
    
    URL = "#{@getGithubApiUrl(true)}repos/#{owner}/#{repo}/commits?#{param}"
    
    options = @getOptions
      method: 'get'
      type: 'github'
      
    fetch(URL, options)
      .then (res) =>
        res.json()
      .then (json) =>
        if json.length > 0
          @updateDate 'fetch-commits'
          @doCommitAddedNotification repo, json
          
  doCommitAddedNotification: (repo, commits)->
    roomId = @getConfig().ENGINEER_ROOM
    
    message = @createCommitAddedMessage repo, commits
    
    @say roomId, message
      
  createCommitAddedMessage: (repo, commits) ->
    messages = "[info][title](cracker)(cracker)(cracker){repo}に#{commits.length}件#Commitされました(cracker)(cracker)(cracker)[/title]"
    
    for commit in commits
      message = "#{commit.sha.substring(0, 7)}: #{commit.commit.message} - #{commit.commit.author.name}\n"
      message += "#{commit.html_url}" 
      
      messages += "#{message}\n"
      
    return "#{messages}[/info]"
    
  getGithubApiUrl: (isPrivate = false) ->
    if isPrivate
      return "https://#{@getConfig().GITHUB_USERNAME}:#{@getConfig().GITHUB_TOKEN}@api.github.com/"
    else
      return 'https://api.github.com/'
      
  getConfig: ->
    CSON.readFileSync('./config.cson')
    
  watchRoom: (roomId)->
    
    URL = "#{@API_URL}/rooms/#{roomId}/messages"
    options = @getOptions()
    console.log options, URL
    
    fetch(URL, options)
      .then (res) ->
        console.log res
        res.json()
      .then (json) ->
        console.log json
