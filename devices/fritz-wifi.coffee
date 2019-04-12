module.exports = (env) ->

  # libraries
  t = env.require('decl-api').types
  _ = env.require 'lodash'


  # ###FritzWifi class
  class FritzWifi extends env.devices.SwitchActuator

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
    constructor: (@config, @plugin, lastState) ->
      @id = @config.id
      @name = @config.name
      @interval = 1000 * (@config.interval or @plugin.config.interval)
      @caller = @plugin.caller @config.box

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

    # Returns a promise that is fulfilled when done.
    changeStateTo: (state) ->
      @caller.call "setGuestWlan", state
        .then (settings) =>
          throw "Could not set guest WLAN state" if state != settings.activate_guest_access
          @_setState(if settings.activate_guest_access then on else off)
          @_setSsid(settings.guest_ssid)
          @_setPsk(settings.wpa_key)
          Promise.resolve()

    # poll device according to interval
    requestUpdate: ->
      @caller.call "getGuestWlan"
        .then (settings) =>
          @_setState(if settings.activate_guest_access then on else off)
          @_setSsid(settings.guest_ssid)
          @_setPsk(settings.wpa_key)
        .catch (error) =>
          if not error.response?
            env.logger.error error.message
