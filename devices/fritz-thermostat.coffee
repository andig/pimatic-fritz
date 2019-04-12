module.exports = (env) ->

  # libraries
  t = env.require('decl-api').types
  _ = env.require 'lodash'


  # ###FritzThermostat class
  # FritzThermostat devices are a hybrif of
  #   env.devices.HeatingThermostat that they inherit from and
  #   env.devices.TemperatureSensor that are additionally implemented
  class FritzThermostat extends env.devices.HeatingThermostat

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

    # implement env.devices.TemperatureSensor
    _temperature: null

    # Initialize device by reading entity definition from middleware
    constructor: (@config, @plugin, lastState) ->
      @id = @config.id
      @name = @config.name
      @interval = 1000 * (@config.interval or @plugin.config.interval)
      @caller = @plugin.caller @config.box

      # initial state
      @_temperature = lastState?.temperature?.value
      @_temperatureSetpoint = lastState?.temperatureSetpoint?.value
      @_synced = true

      # implement env.devices.TemperatureSensor
      # @attributes = _.extend @attributes, @customAttributes

      # get temp settings
      @readDefaultTemperatures()

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
      @caller.call "setTempTarget", @config.ain, temperatureSetpoint
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

    readDefaultTemperatures: ->
      @caller.call "getTempComfort", @config.ain
        .then (temp) =>
          temp = @plugin.clamp temp
          @emit "comfyTemp", temp
          @caller.call "getTempNight", @config.ain
            .then (temp) =>
              temp = @plugin.clamp temp
              @emit "ecoTemp", temp
              @_setSynced(true)
        .catch (error) =>
          if not error.response?
            env.logger.error error.message

    # poll device according to interval
    requestUpdate: ->
      @caller.call "getTemperature", @config.ain
        .then (temp) =>
          temp = @plugin.clamp temp
          @_setTemperature(temp)

          @caller.call "getTempTarget", @config.ain
            .then (temp) =>
              temp = @plugin.clamp temp
              @_setSetpoint(temp)
        .catch (error) =>
          if not error.response?
            env.logger.error error.message
