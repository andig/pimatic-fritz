# #Fritz plugin

module.exports = (env) ->

  # Require the bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  # Require the decl-api library
  t = env.require('decl-api').types

  # Require request
  fritz = require 'smartfritz-promise'



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

      # merge extended options, e.g. for accepting self-signed SSL certificates
      @fritzCall("getSwitchList", @config)
        .then (ains) ->
          env.logger.info "Device AINs: " + ains
        .error (error) ->
          env.logger.error "Cannot access #{error.options?.url}: #{error.response?.statusCode}"

      @framework.deviceManager.registerDeviceClass("FritzOutlet", {
        configDef: deviceConfigDef.FritzOutlet,
        createCallback: (config) =>
          return new FritzOutletDevice(config, this)
      })

      @framework.deviceManager.registerDeviceClass("FritzWlan", {
        configDef: deviceConfigDef.FritzWlan,
        createCallback: (config) =>
          return new FritzWlanDevice(config, this)
      })

      # # wait till all plugins are loaded
      # @framework.on "after init", =>
      #   # Check if the mobile-frontent was loaded and get a instance
      #   mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
      #   if mobileFrontend?
      #     mobileFrontend.registerAssetFile 'js', "pimatic-fritz/app/fritz-outlet-item.coffee"
      #     mobileFrontend.registerAssetFile 'html', "pimatic-fritz/app/fritz.jade"
      #   else
      #     env.logger.warn "Could not find the mobile-frontend. No gui will be available"

    # ####fritzCall()
    # `fritzCall` can call functions on the smartfritz api and automatically establish session
    # @todo: implement network retry
    fritzCall: (functionName, ain) =>
      args = [@sid]
      args.push ain if ain
      args.push { url: @config.url }

      env.logger.debug "#{functionName} #{@config.url}, #{@sid}, #{ain}"

      return (fritz[functionName] args...)
        .error (error) =>
          if error.response?.statusCode == 403
            env.logger.warn "Re-establishing session at " + @config.url
            return fritz.getSessionID(@config.user, @config.password, { url: @config.url })
              .then (sid) =>
                # @todo provide easly handling of sid == '0000000000000000'
                @sid = sid
                # try again with new sid
                args = [sid]
                args.push ain if ain
                args.push { url: @config.url }
                return fritz[functionName] args...
          throw error


  class FritzOutletDevice extends env.devices.SwitchActuator
    # attributes
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

    # actions
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
    constructor: (@config, @plugin) ->
      @name = config.name
      @id = config.id
      @interval = 1000 * (config.interval or plugin.config.interval)

      # keep updating
      @requestUpdate()
      setInterval( =>
        @requestUpdate()
      , @interval
      )
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
              @_setEnergy(energy / 1000.0)
        .error (error) ->
          env.logger.error "Cannot access #{error.options?.url}: #{error.response?.statusCode}"

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
        .then (state) =>
          @_setState(if state then on else off)
          Promise.resolve()


  class FritzWlanDevice extends env.devices.SwitchActuator
    # attributes
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

    # actions
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
    constructor: (@config, @plugin) ->
      @name = config.name
      @id = config.id
      @interval = 1000 * (config.interval or plugin.config.interval)

      # keep updating
      @requestUpdate()
      setInterval( =>
        @requestUpdate()
      , @interval
      )
      super()

    # poll device according to interval
    requestUpdate: ->
      @plugin.fritzCall("getGuestWlan")
        .then (settings) =>
          console.log settings
          @_setState(if settings.activate_guest_access then on else off)
          @_setSsid(settings.guest_ssid)
          @_setPsk(settings.wpa_key)
        .error (error) ->
          env.logger.error "Cannot access #{error.options?.url}: #{error.response?.statusCode}"

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
          @_setState(if settings.activate_guest_access then on else off)
          @_setSsid(settings.guest_ssid)
          @_setPsk(settings.wpa_key)
          Promise.resolve()


  # ###Finally
  fritzPlugin = new FritzPlugin
  return fritzPlugin
