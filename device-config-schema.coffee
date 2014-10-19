module.exports = {
  title: "Fritz"
  FritzOutlet: {
    title: "Fritz!DECT 200 outlet"
    type: "object"
    properties:
      ain:
        description: "Device AIN"
        type: "string"
    interval:
      description: "Polling interval for switch state in seconds"
      type: "number"
      default: 0
  }
  FritzWlan: {
    title: "Fritz!Box guest wlan"
    type: "object"
  }
}