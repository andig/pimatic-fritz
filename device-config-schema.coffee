module.exports = {
  title: "Fritz"
  FritzOutlet: {
    title: "Fritz!DECT 200 outlet"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      ain:
        description: "Device AIN"
        type: "string"
      interval:
        description: "Polling interval for switch state in seconds"
        type: "number"
        default: 0
      legacyMode:
        description: "Legacy mode to support older Fritz!OS versions (< 6.20) not supporting 'getDeviceListInfo' method"
        default: false
  }
  FritzWlan: {
    title: "Fritz!Box guest WLAN"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      interval:
        description: "Polling interval for WLAN state in seconds"
        type: "number"
        default: 1800
  }
}