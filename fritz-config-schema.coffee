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
      default: ""
    password:
      description: "Fritz!Box password"
      type: "string"
      default: ""
}