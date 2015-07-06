Shiina = require './Shiina'
shiina = new Shiina
later = require 'later'




checkingCommits = =>
  shiina.fetchCommits('org', 'repo')

textSched = later.parse.text('every 3 second')
later.setInterval(checkingCommits, textSched)