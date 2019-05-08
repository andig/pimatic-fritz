# #Fritz plugin

module.exports = (env) ->

  # libraries
  Promise = env.require 'bluebird'
  _ = env.require 'lodash'

  # Require https://github.com/andig/fritzapi
  fritz = require 'fritzapi'

  deviceConfigTemplates = [
    {
      "name": "Wifi",
      "class": "FritzWifi",
    },
    {
      "name": "Outlet",
      "class": "FritzOutlet",
    },
    {
      "name": "Thermostat",
      "class": "FritzThermostat",
    },
    {
      "name": "Temperature Sensor",
      "class": "FritzTemperatureSensor",
    },
    {
      "name": "Contact Sensor",
      "class": "FritzContactSensor",
    }
  ]


  # ###FritzPlugin class
  class FritzPlugin extends env.plugins.Plugin

    callers: {}

    # ####init()
    # The `init` function is called by the framework to ask your plugin to initialise.
    #
    # #####params:
    #  * `app` is the [express] instance the framework is using.
    #  * `framework` the framework itself
    #  * `config` the properties the user specified as config for your plugin in the `plugins`
    #     section of the config.json file
    #
    init: (app, @framework, @config) =>
      # add boxes to device config enum
      deviceConfigDef = require("./device-config-schema")
      boxes = _.map @config.devices, (device) => device.name
      for own devClass, devDefinition of deviceConfigDef 
        do (devClass, devDefinition) =>
          if devDefinition.properties?.box?.enum?
            devDefinition.properties?.box["enum"] = boxes

      # register devices
      for device in deviceConfigTemplates
        className = device.class
        # convert camel-case classname to kebap-case filename
        filename = className.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase()
        classType = require('./devices/' + filename)(env)
        env.logger.debug "Registering device class #{className}"
        @framework.deviceManager.registerDeviceClass(className, {
          configDef: deviceConfigDef[className],
          createCallback: @_callbackHandler(className, classType)
        })

      # create callers
      for box in @config.devices
        @callers[box.name] = new FritzCaller @framework, box

      # auto discovery
      @framework.deviceManager.on('discover', (eventData) =>
        # for all fritz boxes
        for box in @config.devices
          @framework.deviceManager.discoverMessage 'pimatic-fritz', "Scanning #{box.name} devices"
          caller = @caller box.name

          # wifi
          @framework.deviceManager.discoveredDevice 'pimatic-fritz', "Guest Wifi", {
            class: "FritzWifi",
            box: box.name,
            id: "wifi-#{box.name}"
          }

          Promise.all [            
            caller.call("getSwitchList"),
            caller.call("getThermostatList"),
            caller.call("getDeviceListFiltered", { functionbitmask: fritz.FUNCTION_ALARM }),
          ]
          .then (devices) =>
            [outlets, thermostats, alarms] = devices

            # switches
            for ain in outlets
              caller.discoveredDevice "FritzOutlet", ain

            # thermostats
            for ain in thermostats
              caller.discoveredDevice "FritzThermostat", ain
              caller.discoveredDevice "FritzTemperatureSensor", ain

            # alarm sensors
            for device in alarms
              ain = device.identifier
              caller.discoveredDevice "FritzContactSensor", ain
      )
      return

    _callbackHandler: (className, classType) ->
      # this closure is required to keep the className and classType
      # context as part of the iteration
      return (config, lastState) =>
        return new classType(config, @, lastState)

    # get handler for fritzbox instance
    caller: (name) =>
      if @callers[name]?
        return @callers[name]
      env.logger.error "invalid box name: " + name

    clamp: (temp) =>
      if temp is "on"
        return fritz.MAX_TEMP # indicate "high temp"
      else if temp is "off"
        return fritz.MIN_TEMP # indicate "low temp"
      return temp



  # ###FritzCaller class
  class FritzCaller

    promise: null
    sid: null

    constructor: (@framework, @box) ->
      # create class map
      short = _.map deviceConfigTemplates, (def) -> 
        def.short = _.lowerCase def.class.replace("Fritz", "")
      @deviceConfigDef = _.keyBy deviceConfigTemplates, "class"

    discoveredDevice: (type, ain) =>
      def = @deviceConfigDef[type]
      if not def
        env.logger.error "Invalid device type #{type}"
        return

      config = {
        class: def.class,
        box: @box.name,
        id: "#{def.short}-#{@box.name}-#{ain}",
        ain: ain
      }

      for device in @framework.deviceManager.devicesConfig
        matched = @framework.deviceManager.devicesConfig.some (element, iterator) =>
          config.id is device.id

      if not matched
        deviceName = "#{def.name} (#{ain})"
        process.nextTick @_discoveryCallbackHandler('pimatic-fritz', deviceName, config)
        return config

    _discoveryCallbackHandler: (pluginName, deviceName, deviceConfig) ->
      return () =>
        @framework.deviceManager.discoveredDevice pluginName, deviceName, deviceConfig

    # ####call()
    # `call` can call functions on the smartfritz api and automatically establish session
    # @todo: implement network retry
    call: (functionName, args...) =>
      # chain calls to the FritzBox to obtain single session id, make sure we have a promise in the first place
      return @promise = (@promise || Promise.resolve()).reflect().then =>
        env.logger.debug "#{@box.name} #{functionName} #{@sid} " + (args||[]).join(" ")
        return (fritz[functionName] @sid, args..., { url: @box.url })
          .catch (error) =>
            if error.response?.statusCode == 403
              env.logger.warn "Re-establishing session at #{@box.url || "default"}"
              return fritz.getSessionID(@box.user, @box.password, { url: @box.url })
                .then (@sid) =>
                  return fritz[functionName] @sid, args..., { url: @box.url } # retry with new sid
                .catch =>
                  # handle sid == '0000000000000000'
                  throw new Error "Invalid Session-Id: Invalid username or password"

            env.logger.error "Cannot access #{error.options?.url}: #{error.response?.statusCode}"
            throw error


  # ###Finally
  fritzPlugin = new FritzPlugin
  return fritzPlugin
