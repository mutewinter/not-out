# Print out what commits have not been pushed to a given environment.
#
# Usage
#
# # See what's not out on production.
# coffee ./bin/index.coffee user/repo production
# # See what's not out on staging.
# coffee ./bin/index.coffee user/repo staging
# # See what's happened in the last week.
# coffee ./bin/index.coffee user/repo master@{7days}

diff = require './lib/diff'
version = require './lib/version'
_ = require 'lodash'

environments = ['development', 'staging', 'production']

githubRepo = process.argv[2]
target = process.argv[3]

if !target
  console.log """
    Invalid first argument. Should be an environment (#{environments.join(',')})
    or a diff target
  """
  process.exit()

if _.includes(environments, process.argv[2])
  environment = target
  appHost =
    switch target
      when 'development' then process.env.NOT_OUT_DEVELOPMENT
      when 'staging'     then process.env.NOT_OUT_STAGING
      when 'production'  then process.env.NOT_OUT_PRODUCTION_HOST
  version(appHost).then (version) ->
    diff(githubRepo, version, 'master',
      showLastDeployEstimate: true
      parameters:
        environment: environment
      messages:
        empty: "No commits have not been pushed to ${environment}"
        summary: "${message} ${verb} not been pushed to ${environment}."
    )
else
  base = githubRepo
  head = 'master'
  diff(firstArg, base, head,
    parameters:
      base: base
      head: head
    messages:
      empty: "No commits between ${base} and ${head}."
      summary: "${message} between ${base} and ${head}."
  )
