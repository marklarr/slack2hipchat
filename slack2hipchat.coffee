# Description:
#   A way to communicate between Slack and HipChat users. 

Util = require "util"

HIP_CHAT_AUTH_TOKEN =  process.env.HIP_CHAT_AUTH_TOKEN
SLACK_WEBHOOK_URL = process.env.SLACK_WEBHOOK_URL
ROOM_NAME = 'sf'
SIGNATURE_PREFIX = "s2h"

module.exports = (robot) ->
  robot.hear ///^(?!(\(#{SIGNATURE_PREFIX}\))).*$///i, (msg) ->
    if msg.envelope.room == 'sf'
      if HIP_CHAT_AUTH_TOKEN
        sendToHipChat( msg)
      else if SLACK_WEBHOOK_URL
        sendToSlack(msg)

sendToHipChat = (msg) ->
  data = urlEncode({
         message: "(#{SIGNATURE_PREFIX}) #{userMessageText(msg)}",
         message_format: "text",
         from: msg.envelope.user['name'],
         room_id: "sf"
       })

       hipChatPost msg, "/rooms/message", data, (err, res, body) ->
         msg.send Util.inspect(body)
         msg.send Util.inspect(err)
         msg.send Util.inspect(res)

sendToSlack = (msg) ->
  data = JSON.stringify({
         channel: "##{ROOM_NAME}",
         text: "(#{SIGNATURE_PREFIX}) #{msg.envelope.message.text}",
         username: msg.envelope.user['name'],
         icon_emoji: ":snake:"
       })

       slackWebhookPost msg, data
       
urlEncode = (object) ->
  chunks = []
  for key, value of object
    chunks.push urlEncodeValue(key) + '=' + urlEncodeValue(value)
  chunks.sort().join '&'

urlEncodeValue = (object) ->
  encodeURIComponent(object.toString()).replace(/\!/g, '%21').
    replace(/'/g, '%27').replace(/\(/g, '%28').replace(/\)/g, '%29').
    replace(/\*/g, '%2A')

userMessageText = (msg) ->
  "#{msg.envelope.user['name']}: #{msg.envelope.message.text}"

hipChatPost = (httpable, path, data, cb) ->
  httpable.http("https://api.hipchat.com/v1/#{path}?format=json&auth_token=#{HIP_CHAT_AUTH_TOKEN}").header('Content-Type', 'application/json').post(data) (err, res, body) ->
    cb(err, res, body) if cb

slackWebhookPost = (httpable, data, cb) ->
  httpable.http(SLACK_WEBHOOK_URL).post(data) (err, res, body) ->
    cb(err, res, body) if cb
