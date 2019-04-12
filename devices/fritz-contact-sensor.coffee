module.exports = (env) ->

  # libraries
  t = env.require('decl-api').types
  _ = env.require 'lodash'


  # ###FritzContactSensor class
  # FritzContactSensor device models the window open sensors (HAN FUN or DECT)
  class FritzContactSensor extends env.devices.ContactSensor

    # Initialize device by reading entity definition from middleware
    constructor: (@config, @plugin, lastState) ->
      @id = @config.id
      @name = @config.name
      @interval = 1000 * (@config.interval or @plugin.config.interval)
      @caller = @plugin.caller @config.box

      # initial state
      @_contact = lastState?.contact?.value

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
      @caller.call "getDeviceListFiltered", { identifier: @config.ain }
        .then (devices) =>
          if devices[0]?.alert?
            @_setContact(1-devices[0].alert.state)
        .catch (error) =>
          if not error.response?
            env.logger.error error.message
