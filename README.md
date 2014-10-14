pimatic volkszaehler plugin
===========================

Volkszaehler plugin enables connecting the [volkszahler.org](http://volkszahler.org) smart meter application to [pimatic](http://pimatic.org) automation server.

**NOTE** currently, volkszahler master branch does not contain the needed patches to push data to pimatic.

Plugin Configuration
-------------
You can load the plugin by editing your `config.json` to include:

    {
      "plugin": "volkszaehler",
      "middleware": "http://127.0.0.1/middleware.php", // url of the volkszaehler middleware
    }

The middleware url is needed to retrieve th volkszaehler installation's capabilities, especially the [entity type definitions](https://github.com/volkszaehler/volkszaehler.org/blob/master/lib/Volkszaehler/Definition/EntityDefinition.json).

Device Configuration
-------------
Devices are linked to volkszaehler channels by specifying the `class`, `middleware` and `uuid` properties:

	...
	"devices": [
	{
		"id": "home-bezug",
		"name": "Kanal 1",
		"class": "Volkszaehler",
		"middleware": "http://127.0.0.1/middleware.php", // url of the device's middleware
		"uuid": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx"
	},
	...

As `middleware` can be configured per device, multiple volkszaehler installations can be connected as long as their capabiltiies match.
