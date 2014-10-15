pimatic fritz plugin
===========================

Fritz plugin enables connecting FritzDECT devices to [pimatic](http://pimatic.org) automation server.

Plugin Configuration
-------------
You can load the plugin by editing your `config.json` to include:

    {
      "plugin": "fritz",
      "url": "http://fritz.box", // url of the FritzBox
      "user": "username" // FritzBox user
      "password": "password" // FritzBox password
      "timeout": 60 // Polling interval for the FritzDECT switches
    }

Device Configuration
-------------
Devices are linked to fritz plugin channels by specifying the `class`, `middleware` and `ain` properties:

	...
	"devices": [
	{
		"id": "home-switch",
		"name": "Fritz outlet",
		"class": "FritzOutlet",
		"ain": "xxxxxxxxx" // ain of the fritz switch
	},
	...

A list of available fritz switch AINs will be logged to the pimatic console when the plugin is enabled.
