rest = require 'restler'
_ = require 'lodash'
toSentence = require('underscore.string/toSentence')
GitHubApi = require 'github'
moment = require 'moment'
Promise = require 'bluebird'

TYPE_RE = /(^(\w+)):/

ACCESS_TOKEN = process.env.NOT_OUT_GITHUB_ACCESS_TOKEN

if !ACCESS_TOKEN
  console.log 'No access token found, exitting.'
  process.exit()

github = new GitHubApi(version: "3.0.0")
github.authenticate(type: 'oauth', token: ACCESS_TOKEN)

diff = (fullRepoName, base, head, options = {}) ->
  new Promise (resolve, reject) ->
    finalMessages = []
    [user, repo] = fullRepoName.split('/')
    emptyMessage = _.template(options.messages.empty)
    summaryMessage = _.template(options.messages.summary)
    diffURL = "https://github.com/#{user}/#{repo}/compare/#{base}...#{head}"

    github.repos.compareCommits(
      user: user
      repo: repo
      base: base
      head: head
    , (error, data) ->
      messages = []
      if error
        finalMessages.push "Error fetching commit diff for #{user}/#{repo}"
        finalMessages.push "Using base: #{base} and head: #{head}"
        finalMessages.push "View the diff #{diffURL}"
        return resolve(finalMessages)

      commits = data.commits

      if commits.length is 0
        finalMessages.push emptyMessage(options.parameters)
        return resolve(finalMessages)

      groupedCommits = _.groupBy commits, (commit) ->
        type = commit.commit.message.match(TYPE_RE)?[1]
        type = 'merge' if /^Merge/.test(commit.commit.message)
        if _.includes(['feat', 'fix', 'merge'], type) then type else 'other'

      features = groupedCommits.feat?.length
      fixes = groupedCommits.fix?.length
      other = groupedCommits.other?.length

      messageParts = [
        if features
          "#{features} :sparkles: feature#{if features is 1 then '' else 's'}"
        if fixes
          "#{fixes} :bug: fix#{if fixes is 1 then '' else 'es'}"
        if other
          "#{other} other commit#{if other is 1 then '' else 's'}"
      ]
      message = toSentence(_.compact(messageParts))
      verb = if commits.length is 1 then 'has' else 'have'
      summary = summaryMessage(
        _.merge({}, options.parameters, message: message, verb: verb)
      )

      oldestCommitDate = moment(_.first(commits).commit.committer.date)
      lastDeployMessage = "Estimated last deploy: #{oldestCommitDate.fromNow()}."
      if options.showLastDeployEstimate
        finalMessages.push("#{summary} #{lastDeployMessage}")
      else
        finalMessages.push(summary)

      finalMessages.push('\n')

      # Individaul commit messages
      messages = []
      ['feat', 'fix', 'other'].forEach (commitType) ->
        commits = groupedCommits[commitType]
        return unless commits?.length

        perCommitMessages = commits.reverse().map (commit) ->
          login = commit.author.login
          message = commit.commit.message.split('\n')[0]
          message = message.replace(TYPE_RE, '').trim()
          date = moment(commit.commit.committer.date)
          "- #{message} @#{login} (#{date.fromNow()})"

        switch commitType
          when 'feat'
            heading = ":sparkles: feature#{if features is 1 then '' else 's'}"
          when 'fix'
            heading = ":bug: fix#{if fixes is 1 then '' else 'es'}"
          when 'other'
            heading = "Other commit#{if other is 1 then '' else 's'}"
          when 'merge'
            # Skip merge commits
            return
          else
            finalMessages.push "Error: Invalid commit type #{commitType}"

        finalMessage = "#{heading}\n#{perCommitMessages.join('\n')}"
        messages.push(finalMessage)

      finalMessages.push messages.join('\n\n')
      finalMessages.push "\nView the whole diff #{diffURL}"
    )


module.exports = diff
