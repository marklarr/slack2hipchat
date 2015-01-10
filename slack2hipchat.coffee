# Description:
#   A way to communicate between Slack and HipChat users. 

Util = require "util"

HIP_CHAT_AUTH_TOKEN =  process.env.HIP_CHAT_AUTH_TOKEN  #'mBIoh7idKqS8bJAALwwfVu904R7AY8uOIioBQ0wr'
SLACK_WEBOOK_URL = process.env.SLACK_WEBOOK_URL #'https://hooks.slack.com/services/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'
ROOM_NAME = 'sf'
SIGNATURE_PREFIX = "slack2hipchat"

module.exports = (robot) ->
  robot.hear ///^(?!(\(#{SIGNATURE_PREFIX}\))).*$///i, (msg) ->
    if msg.envelope.room == 'sf'
      if HIP_CHAT_AUTH_TOKEN
        sendToHipChat( msg)
      else if SLACK_WEBOOK_URL
        sendToSlack(msg)

sendToHipChat = (msg) ->
  data = JSON.stringify({
         message: "(#{SIGNATURE_PREFIX}) #{userMessageText(msg)}",
         color: 'purple',
         message_format: 'text'
       })
       hipChatPost msg, "/room/#{ROOM_NAME}/notification", data

sendToSlack = (msg) ->
  data = JSON.stringify({
         payload: {
           channel: "##{ROOM_NAME}",
           text: "(#{SIGNATURE_PREFIX}) #{msg.envelope.message.text}",
           username: msg.envelope.user['name'],
           icon_emoji: ":snake:"
         }
       })
       slackPost msg, data


userMessageText = (msg) ->
  "#{msg.envelope.user['name']}: #{msg.envelope.message.text}"

hipChatPost = (httpable, path, data, cb) ->
  httpable.http("https://api.hipchat.com/v2/#{path}?format=json&auth_token=#{HIP_CHAT_AUTH_TOKEN}").header('Content-Type', 'application/json').post(data) (err, res, body) ->
    cb(err, res, body) if cb


slackWebhookPost = (httpable, data, cb) ->
  httpable.http(SLACK_WEBOOK_URL).post(data) (err, res, body) ->
    cb(err, res, body) if cb
