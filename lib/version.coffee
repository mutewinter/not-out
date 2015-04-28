rest = require 'restler'
Promise = require 'bluebird'

version = (host) ->
  new Promise (resolve, reject) ->
    rest.get("#{host}/VERSION.txt").on 'complete', (version) ->
      [...,version] = version.replace(/\n$/, '').split('.')
      resolve(version[0..7])

module.exports = version
