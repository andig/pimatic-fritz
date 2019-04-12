# pimatic fritz plugin
[![NPM Version](https://img.shields.io/npm/v/pimatic-fritz.svg)](https://www.npmjs.com/package/pimatic-fritz)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=9NUJAVLPHUSTW)

Fritz plugin enables connecting FritzDECT devices to [pimatic](http://pimatic.org) automation server.

Devices supported are:

- FritzBox (Guest WLAN configuration)
- FritzDECT 200 outlet
- CometDECT thermostat
- both FritzDECT and CometDECT can also be used as temperature sensors
- HAN FUN contact/alarm sensors

*NOTE*: with v0.7 the device configuration has changed to support multiple Fritz!Boxes. Existing devices must be deleted and re-discovered.

## Plugin Configuration

You can load the plugin by editing your `config.json` to include:

    {
      "plugin": "fritz",
      "devices": [
        {
          "name": "box-0", // name of the FritzBox for reference in the device config
          "url": "http://fritz.box", // url of the FritzBox
          "user": "username", // FritzBox user
          "password": "password", // FritzBox password
          "interval": 60 // Polling interval for the FritzDECT switches
        }
      ]
    }


## Device Configuration

Devices can be auto-discovered. Manual configuration is possible, too.

Devices are linked to fritz devices by the given the `class` and `ain` properties. Note, however, the `FritzWlan`
device constitutes a special case. It has has no `ain` property as it is mapped to a function block of the 
FritzBox router:

    ...
    "devices": [
    {
      "box": "box-0",
      "id": "home-switch",
      "name": "Fritz outlet",
      "class": "FritzOutlet",
      "ain": "xxxxxxxxx"
    },
    {
      "box": "box-1",
      "id": "thermostat-1",
      "name": "Thermostat 1",
      "class": "FritzThermostat",
      "ain": "xxxxxxxxx"
    },
    {
      "box": "box-0",
      "id": "temp-1",
      "name": "TemperatureSensor 1",
      "class": "FritzTemperatureSensor",
      "ain": "xxxxxxxxx"
    },
    {
      "box": "box-1",
      "id": "contact-1",
      "name": "ContactSensor 1",
      "class": "FritzContactSensor",
      "ain": "xxxxxxxxx"
    },
    {
      "box": "box-1",
      "id": "guest-wlan",
      "name": "Guest WLAN",
      "class": "FritzWlan"
    },
  ...

A list of available fritz switch, thermostat, and contact sensor AINs will be logged to the pimatic 
console when the plugin is started.
