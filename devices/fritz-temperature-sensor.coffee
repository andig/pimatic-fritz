module.exports = (env) ->

  # libraries
  t = env.require('decl-api').types
  _ = env.require 'lodash'


  # ###FritzTemperatureSensor class
  # FritzTemperatureSensor device models the temperature of the Comet DECT thermostats
  class FritzTemperatureSensor extends env.devices.TemperatureSensor

    # Initialize device by reading entity definition from middleware
    constructor: (@config, @plugin, lastState) ->
      @id = @config.id
      @name = @config.name
      @interval = 1000 * (@config.interval or @plugin.config.interval)
      @caller = @plugin.caller @config.box

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
      @caller.call "getTemperature", @config.ain
        .then (temp) =>
          temp = @plugin.clamp temp
          @_setTemperature(temp)
        .catch (error) =>
          if not error.response?
            env.logger.error error.message
