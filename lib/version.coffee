rest = require 'restler'
Promise = require 'bluebird'

version = (host, versionFile = 'VERSION.txt') ->
  new Promise (resolve, reject) ->
    rest.get("#{host}/#{versionFile}").on 'complete', (version) ->
      parts = version.replace(/\n$/, '').split('.')
      version = parts[parts.length - 1]
      resolve(version[0..7])

module.exports = version
