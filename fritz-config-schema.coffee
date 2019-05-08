# #pimatic-fritz plugin configuration options
module.exports = {
  title: "Fritz plugin config options"
  type: "object"
  properties:
    devices:
      description: "Fritz!Box configuration"
      type: "array"
      items:
        type: "object"
        properties:
          name:
            description: "Fritz!Box name"
            type: "string"
            default: "Main"
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
      description: "Polling interval in seconds"
      type: "number"
      default: 60
}