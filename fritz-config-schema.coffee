# #pimatic-fritz plugin configuration options
module.exports = {
  title: "Fritz plugin config options"
  type: "object"
  properties:
    url:
      description: "Fritz!Box URL"
      type: "string"
      default: "http://fritz.box"
    user:
      description: "Fritz!Box user"
      type: "string"
    password:
      description: "Fritz!Box password"
      type: "string"
    interval:
      description: "Polling interval for switch state in seconds"
      type: "number"
      default: 60
}