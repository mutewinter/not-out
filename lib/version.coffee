rest = require 'restler'
Promise = require 'bluebird'

version = (host) ->
  new Promise (resolve, reject) ->
    rest.get("#{host}/VERSION.txt").on 'complete', (version) ->
      parts = version.replace(/\n$/, '').split('.')
      version = parts[parts.length - 1]
      resolve(version[0..7])

module.exports = version
