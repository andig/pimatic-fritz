pimatic fritz plugin
===========================

Fritz plugin enables connecting FritzDECT devices to [pimatic](http://pimatic.org) automation server.

Plugin Configuration
-------------
You can load the plugin by editing your `config.json` to include:

    {
      "plugin": "fritz",
      "url": "http://fritz.box", // url of the FritzBox
      "user": "username", // FritzBox user
      "password": "password", // FritzBox password
      "interval": 60 // Polling interval for the FritzDECT switches
    }

Device Configuration
-------------
Devices are linked to fritz plugin channels by specifying the `class` and `ain` properties as shown below. 
	
	"devices": [
	{
		"id": "home-switch",
		"name": "Fritz outlet",
		"class": "FritzOutlet",
		"ain": "xxxxxxxxx", // ain of the fritz switch
      	"interval": 60 // Polling interval. Inherited from plugin if not defined.
	},
	

A list of available fritz switch AINs will be logged to the pimatic console when the plugin is enabled.

For routers running a Fritz!OS version smaller than *v6.20* the `legacyMode` property is provided. If set to `true`, 
 different service methods will be used to the read attribute values. Note, however, no temperature reading will be 
 provided if legacy mode has been activated. In this case you may want to hide the temperature attribute as shown 
 below.

	"devices": [
	{
		"id": "home-switch",
		"name": "Fritz outlet",
		"class": "FritzOutlet",
		"legacyMode": true,
		"ain": "xxxxxxxxx", // ain of the fritz switch
      	"interval": 60, // Polling interval. Inherited from plugin if not defined.
      	"xAttributeOptions": [
                {
                  "name": "temperature",
                  "hidden": true
                }
        ]
	},
