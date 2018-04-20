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


## Plugin Configuration

You can load the plugin by editing your `config.json` to include:

    {
      "plugin": "fritz",
      "url": "http://fritz.box", // url of the FritzBox
      "user": "username", // FritzBox user
      "password": "password", // FritzBox password
      "interval": 60 // Polling interval for the FritzDECT switches
    }


## Device Configuration

Devices are linked to fritz plugin channels by specifying the `class`, `middleware` and `ain` properties:

    ...
    "devices": [
    {
      "id": "home-switch",
      "name": "Fritz outlet",
      "class": "FritzOutlet",
      "ain": "xxxxxxxxx"
    },
    {
      "id": "thermostat-1",
      "name": "Thermostat 1",
      "class": "FritzThermostat",
      "ain": "xxxxxxxxx"
    },
    {
      "id": "temp-1",
      "name": "TemperatureSensor 1",
      "class": "FritzTemperatureSensor",
      "ain": "xxxxxxxxx"
    },
    },
    {
      "id": "contact-1",
      "name": "ContactSensor 1",
      "class": "FritzContactSensor",
      "ain": "xxxxxxxxx"
    },
    {
      "id": "guest-wlan",
      "name": "Guest WLAN",
      "class": "FritzWlan"
    },
  ...

A list of available fritz switch and thermostat AINs will be logged to the pimatic console when the plugin is started.
