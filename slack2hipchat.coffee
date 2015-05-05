# Description:
#   A way to communicate between Slack and HipChat users. 

# config for Slack users talking to a foreign HipChat
HIP_CHAT_AUTH_TOKEN =  process.env.HIP_CHAT_AUTH_TOKEN
HIP_CHAT_ROOM_EMOJI = process.env.HIP_CHAT_ROOM_EMOJI or ":snake:"  # affects received message presentation in Slack
HIP_CHAT_MESSAGE_COLOR = process.env.HIP_CHAT_MESSAGE_COLOR or "purple"
HIP_CHAT_NOTIFY = process.env.HIP_CHAT_NOTIFY or 1  # HipChat API specifies 0 = false, 1 = true for this parameter

# config for HipChat users talking to a foreign Slack
SLACK_WEBHOOK_URL = process.env.SLACK_WEBHOOK_URL

# shared config
ROOM_NAMES = process.env.SLACK_2_HIPCHAT_ROOMS or ["sf"]
SIGNATURE_PREFIX = "s2h"  # in Slack, will appear as ":s2h:"; in HipChat, as "(s2h)" - recommended: make a custom emoji/emote!

module.exports = (robot) ->
  robot.hear ///^(?!((\(|\:)#{SIGNATURE_PREFIX}(\)|\:))).*$///i, (msg) ->
    if msg.envelope.room in ROOM_NAMES
      if HIP_CHAT_AUTH_TOKEN
        sendToHipChat(msg)
      else if SLACK_WEBHOOK_URL
        sendToSlack(msg)

sendToHipChat = (msg) ->
  data = urlEncode({
         room_id: msg.envelope.room,
         message: "(#{SIGNATURE_PREFIX}) #{msg.envelope.message.text}",
         message_format: "text",
         from: msg.envelope.user['name'],
         color: HIP_CHAT_MESSAGE_COLOR,
         notify: HIP_CHAT_NOTIFY
       })

       hipChatPost msg, "/rooms/message", data

sendToSlack = (msg) ->
  data = JSON.stringify({
         channel: "##{msg.envelope.room}",
         text: ":#{SIGNATURE_PREFIX}: #{msg.envelope.message.text}",
         username: msg.envelope.user['name'],
         icon_emoji: HIP_CHAT_ROOM_EMOJI
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
  httpable.http("https://api.hipchat.com/v1/#{path}?format=json&auth_token=#{HIP_CHAT_AUTH_TOKEN}").header('Content-Type', 'application/x-www-form-urlencoded').post(data) (err, res, body) ->
    cb(err, res, body) if cb

slackWebhookPost = (httpable, data, cb) ->
  httpable.http(SLACK_WEBHOOK_URL).post(data) (err, res, body) ->
    cb(err, res, body) if cb
