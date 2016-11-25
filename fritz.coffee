# #Fritz plugin

module.exports = (env) ->

  # libraries
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  t = env.require('decl-api').types
  _ = env.require 'lodash'

  # Require https://github.com/andig/fritzapi
  fritz = require 'fritzapi'


  # ###FritzPlugin class
  class FritzPlugin extends env.plugins.Plugin

    # Fritz session id
    sid: null

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
      # register devices
      deviceConfigDef = require("./device-config-schema")

      # switch list
      @fritzCall("getSwitchList")
        .then (ains) =>
          env.logger.info "Switch AINs: " + ains
          # thermostat list
          @fritzCall("getThermostatList")
            .then (ains) ->
              env.logger.info "Thermostat AINs: " + ains

      # auto discovery
      @framework.deviceManager.on('discover', (eventData) =>
        @framework.deviceManager.discoverMessage(
          'pimatic-fritz', "Scanning DECT devices"
        )

        @fritzCall("getSwitchList")
          .then (ains) =>
            for ain in ains
              config = {
                class: 'FritzOutlet',
                id: "switch-" + ain,
                ain: ain
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-fritz', "Switch (#{ain})", config
              )
        
        # thermostat list
        @fritzCall("getThermostatList")
          .then (ains) =>
            for ain in ains
              config = {
                class: 'FritzThermostat',
                id: "thermostat-" + ain,
                ain: ain
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-fritz', "Thermostat (#{ain})", config
              )
              config = {
                class: 'FritzTemperatureSensor',
                id: "temperature-" + ain,
                ain: ain
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-fritz', "Temperature sensor (#{ain})", config
              )
      )

      @framework.deviceManager.registerDeviceClass("FritzOutlet", {
        configDef: deviceConfigDef.FritzOutlet,
        createCallback: (config, lastState) =>
          return new FritzOutletDevice(config, lastState, this)
      })

      @framework.deviceManager.registerDeviceClass("FritzWlan", {
        configDef: deviceConfigDef.FritzWlan,
        createCallback: (config, lastState) =>
          return new FritzWlanDevice(config, lastState, this)
      })

      @framework.deviceManager.registerDeviceClass("FritzThermostat", {
        configDef: deviceConfigDef.FritzThermostat,
        createCallback: (config, lastState) =>
          return new FritzThermostatDevice(config, lastState, this)
      })

      @framework.deviceManager.registerDeviceClass("FritzTemperatureSensor", {
        configDef: deviceConfigDef.FritzTemperatureSensor,
        createCallback: (config, lastState) =>
          return new FritzTemperatureSensorDevice(config, lastState, this)
      })

      # # wait till all plugins are loaded
      # @framework.on "after init", =>
      #   mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
      #   if mobileFrontend?
      #     mobileFrontend.registerAssetFile 'js', "pimatic-fritz/simplethermostat-item.coffee"
      #     mobileFrontend.registerAssetFile 'html', "pimatic-fritz/simplethermostat-item.jade"
      return

    # ####fritzCall()
    # `fritzCall` can call functions on the smartfritz api and automatically establish session
    # @todo: implement network retry
    fritzCall: (functionName, args...) =>
      # chain calls to the FritzBox to obtain single session id, make sure we have a promise in the first place
      return @fritzPromise = (@fritzPromise or Promise.resolve()).reflect().then =>
        env.logger.debug "#{functionName} #{@sid} " + (args||[]).join(" ")
        return (fritz[functionName] @sid, args..., { url: @config.url })
          .catch (error) =>
            if error.response?.statusCode == 403
              env.logger.warn "Re-establishing session at " + @config.url
              return fritz.getSessionID(@config.user, @config.password, { url: @config.url })
                .then (@sid) =>
                  # @todo provide handling of sid == '0000000000000000'
                  return fritz[functionName] @sid, args..., { url: @config.url } # retry with new sid
            env.logger.error "Cannot access #{error.options?.url}: #{error.response?.statusCode}"
            throw error

    fritzClampTemperature: (temp) =>
      if temp is "on"
        return fritz.MAX_TEMP # indicate "high temp"
      else if temp is "off"
        return fritz.MIN_TEMP # indicate "low temp"
      return temp


  # ###FritzOutletDevice class
  class FritzOutletDevice extends env.devices.SwitchActuator

    attributes:
      state:
        description: "Current state of the outlet"
        type: t.boolean
        labels: ['on', 'off']
      power:
        description: "Current power"
        type: t.number
        unit: 'W'
      energy:
        description: "Total energy"
        type: t.number
        unit: 'kWh'
        displaySparkline: false

    actions:
      turnOn:
        description: "turns the outlet on"
      turnOff:
        description: "turns the outlet off"
      changeStateTo:
        description: "changes the outlet to on or off"
        params:
          state:
            type: t.boolean
      toggle:
        description: "toggle the state of the outlet"
      getState:
        description: "returns the current state of the outlet"
        returns:
          state:
            type: t.boolean

    # template: 'fritz-outlet'

    # status variables
    _power: null
    _energy: null
    _state: null

    # Initialize device by reading entity definition from middleware
    constructor: (@config, lastState, @plugin) ->
      @id = @config.id
      @name = @config.name
      @interval = 1000 * (@config.interval or @plugin.config.interval)

      # keep updating
      @requestUpdate()
      @intervalTimerID = setInterval( =>
        @requestUpdate()
      , @interval
      )
      super()

    destroy: () ->
      if @intervalTimerID?
        clearInterval @intervalTimerID
      super()

    # poll device according to interval
    requestUpdate: ->
      @plugin.fritzCall("getSwitchState", @config.ain)
        .then (state) =>
          @_setState(if state then on else off)
          @plugin.fritzCall("getSwitchPower", @config.ain)
          .then (power) =>
            @_setPower(power)
            @plugin.fritzCall("getSwitchEnergy", @config.ain)
            .then (energy) =>
              @_setEnergy(Math.round(energy / 100.0) / 10.0)

    # Get current value of last update in defined unit
    getPower: -> Promise.resolve(@_power)

    _setPower: (power) ->
      if @_power is power then return
      @_power = power
      @emit "power", power

    # Get total value of last update in defined unit
    getEnergy: -> Promise.resolve(@_energy)

    _setEnergy: (energy) ->
      if @_energy is energy then return
      @_energy = energy
      @emit "energy", energy

    # Retuns a promise that is fulfilled when done.
    changeStateTo: (state) ->
      @plugin.fritzCall((if state then "setSwitchOn" else "setSwitchOff"), @config.ain)
        .then (newState) =>
          throw "Could not set switch state" if state != newState
          @_setState(if newState then on else off)
          Promise.resolve()


  # ###FritzWlanDevice class
  class FritzWlanDevice extends env.devices.SwitchActuator

    attributes:
      state:
        description: "Current state of the guest wlan"
        type: t.boolean
        labels: ['on', 'off']
      ssid:
        description: "SSID"
        type: t.string
      psk:
        description: "PSK"
        type: t.string

    actions:
      turnOn:
        description: "turns the guest wlan on"
      turnOff:
        description: "turns the guest wlan off"
      changeStateTo:
        description: "changes the guest wlan to on or off"
        params:
          state:
            type: t.boolean
      toggle:
        description: "toggle the state of the guest wlan"
      getState:
        description: "returns the current state of the guest wlan"
        returns:
          state:
            type: t.boolean

    # status variables
    _ssid: null
    _psk: null
    _state: null

    # Initialize device by reading entity definition from middleware
    constructor: (@config, lastState, @plugin) ->
      @id = @config.id
      @name = @config.name
      @interval = 1000 * (@config.interval or @plugin.config.interval)

      # keep updating
      @requestUpdate()
      @intervalTimerID = setInterval( =>
        @requestUpdate()
      , @interval
      )
      super()

    destroy: () ->
      if @intervalTimerID?
        clearInterval @intervalTimerID
      super()
      
    # poll device according to interval
    requestUpdate: ->
      @plugin.fritzCall("getGuestWlan")
        .then (settings) =>
          @_setState(if settings.activate_guest_access then on else off)
          @_setSsid(settings.guest_ssid)
          @_setPsk(settings.wpa_key)

    # Get current value of last update
    getSsid: -> Promise.resolve(@_ssid)

    _setSsid: (ssid) ->
      if @_ssid is ssid then return
      @_ssid = ssid
      @emit "ssid", ssid

    getPsk: -> Promise.resolve(@_psk)

    _setPsk: (psk) ->
      if @_psk is psk then return
      @_psk = psk
      @emit "psk", psk

    # Retuns a promise that is fulfilled when done.
    changeStateTo: (state) ->
      @plugin.fritzCall("setGuestWlan", state)
        .then (settings) =>
          throw "Could not set guest WLAN state" if state != settings.activate_guest_access
          @_setState(if settings.activate_guest_access then on else off)
          @_setSsid(settings.guest_ssid)
          @_setPsk(settings.wpa_key)
          Promise.resolve()


  # ###FritzThermostat class
  # FritzThermostat devices are a hybrif of
  #   env.devices.HeatingThermostat that they inherit from and
  #   env.devices.TemperatureSensor that are additionally implemented
  class FritzThermostatDevice extends env.devices.HeatingThermostat

    # customize HeatingThermostat attributes
    attributes:
      temperatureSetpoint:
        label: "Temperature Setpoint"
        description: "The temp that should be set"
        type: "number"
        discrete: true
        unit: "°C"
      synced:
        description: "Pimatic and thermostat in sync"
        type: "boolean"
      # implement env.devices.TemperatureSensor
      temperature:
        description: "The measured temperature"
        type: t.number
        unit: '°C'
        acronym: 'T'

    # customize HeatingThermostat actions
    actions:
      changeTemperatureTo:
        params:
          temperatureSetpoint:
            type: "number"

    customConfig:
      # guiShowModeControl: false
      # guiShowPresetControl: false
      # guiShowValvePosition: false

    # implement env.devices.TemperatureSensor
    _temperature: null

    # Initialize device by reading entity definition from middleware
    constructor: (@config, lastState, @plugin) ->
      @id = @config.id
      @name = @config.name
      @interval = 1000 * (@config.interval or @plugin.config.interval)

      # initial state
      @_temperature = lastState?.temperature?.value
      @_temperatureSetpoint = lastState?.temperatureSetpoint?.value
      @_synced = true

      # implement env.devices.TemperatureSensor
      # @attributes = _.extend @attributes, @customAttributes
      # remove unsupported gui elements
      @config = _.extend @config, @customConfig

      # get temp settings
      @readDefaultTemparatures()

      # keep updating
      @requestUpdate()
      @intervalTimerID = setInterval( =>
        @requestUpdate()
      , @interval
      )
      super()

    destroy: () ->
      if @intervalTimerID?
        clearInterval @intervalTimerID
      super()
    
    # implement env.devices.HeatingThermostat
    changeTemperatureTo: (temperatureSetpoint) ->
      @_setSynced(false)
      @plugin.fritzCall("setTempTarget", @config.ain, temperatureSetpoint)
        .then (temp) =>
          throw "Could not set temperature setpoint" if temperatureSetpoint != temp
          @_setSetpoint(temperatureSetpoint)
          @_setSynced(true)
          Promise.resolve()

    # implement env.devices.HeatingThermostat
    changeModeTo: (mode) ->
      # changing modes is not supported.
      return Promise.resolve()

    # implement env.devices.TemperatureSensor
    _setTemperature: (value) ->
      if @_temperature is value then return
      @_temperature = value
      @emit 'temperature', value

    # implement env.devices.TemperatureSensor
    getTemperature: -> Promise.resolve(@_temperature)

    readDefaultTemparatures: ->
      @plugin.fritzCall("getTempComfort", @config.ain)
        .then (temp) =>
          temp = @plugin.fritzClampTemperature temp
          @emit "comfyTemp", temp
          @plugin.fritzCall("getTempNight", @config.ain)
            .then (temp) =>
              temp = @plugin.fritzClampTemperature temp
              @emit "ecoTemp", temp
              @_setSynced(true)

    # poll device according to interval
    requestUpdate: ->
      @plugin.fritzCall("getTemperature", @config.ain)
        .then (temp) =>
          temp = @plugin.fritzClampTemperature temp
          @_setTemperature(temp)

          @plugin.fritzCall("getTempTarget", @config.ain)
            .then (temp) =>
              temp = @plugin.fritzClampTemperature temp
              @_setSetpoint(temp)


  # ###FritzTemperatureSensor class
  # FritzTemperatureSensor device models the temperature of the Comet DECT thermostats
  class FritzTemperatureSensorDevice extends env.devices.TemperatureSensor

    # Initialize device by reading entity definition from middleware
    constructor: (@config, lastState, @plugin) ->
      @id = @config.id
      @name = @config.name
      @interval = 1000 * (@config.interval or @plugin.config.interval)

      # initial state
      @_temperature = lastState?.temperature?.value

      # keep updating
      @requestUpdate()
      @intervalTimerID = setInterval( =>
        @requestUpdate()
      , @interval
      )
      super()

    destroy: () ->
      if @intervalTimerID?
        clearInterval @intervalTimerID
      super()
      
    # poll device according to interval
    requestUpdate: ->
      @plugin.fritzCall("getTemperature", @config.ain)
        .then (temp) =>
          temp = @plugin.fritzClampTemperature temp
          @_setTemperature(temp)


  # ###Finally
  fritzPlugin = new FritzPlugin
  return fritzPlugin
