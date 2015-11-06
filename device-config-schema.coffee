module.exports = {
  title: "Fritz device config schemas"
  FritzOutlet: {
    title: "Fritz!DECT 200 outlet"
    type: "object"
    properties:
      ain:
        description: "Device AIN"
        type: "string"
      interval:
        description: "Polling interval in seconds"
        type: "number"
        default: 0
  }
  FritzWlan: {
    title: "Fritz!Box guest WLAN"
    type: "object"
    properties:
      interval:
        description: "Polling interval in seconds"
        type: "number"
        default: 1800
  }
  FritzThermostat: {
    title: "Comet DECT thermostat"
    type: "object"
    properties:
      ain:
        description: "Device AIN"
        type: "string"
      interval:
        description: "Polling interval in seconds"
        type: "number"
        default: 0
      comfyTemp:
        description: "The defined comfy temperature"
        type: "number"
        default: 21
      ecoTemp:
        description: "The defined eco mode temperature"
        type: "number"
        default: 17
      # vacTemp:
      #   description: "The defined vacation mode temperature"
      #   type: "number"
      #   default: 14
      # guiShowModeControl:
      #   description: "Show the mode buttons in the GUI"
      #   type: "boolean"
      #   default: false
      # guiShowPresetControl:
      #   description: "Show the preset temperatures in the GUI"
      #   type: "boolean"
      #   default: true
      guiShowTemperatureInput:
        description: "Show the temperature input spinbox in the GUI"
        type: "boolean"
        default: true
  }
  FritzTemperatureSensor: {
    title: "Comet DECT temperature sensor"
    type: "object"
    properties:
      ain:
        description: "Device AIN"
        type: "string"
      interval:
        description: "Polling interval in seconds"
        type: "number"
        default: 0
  }
}