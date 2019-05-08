module.exports = (env) ->

  # libraries
  t = env.require('decl-api').types
  _ = env.require 'lodash'


  # ###FritzOutlet class
  class FritzOutlet extends env.devices.SwitchActuator

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

    # Returns a promise that is fulfilled when done.
    changeStateTo: (state) ->
      @caller.call (if state then "setSwitchOn" else "setSwitchOff"), @config.ain
        .then (newState) =>
          throw "Could not set switch state" if state != newState
          @_setState(if newState then on else off)
          Promise.resolve()

    # poll device according to interval
    requestUpdate: ->
      @caller.call "getSwitchState", @config.ain
        .then (state) =>
          @_setState(if state then on else off)
          @caller.call "getSwitchPower", @config.ain
            .then (power) =>
              @_setPower(power)
              @caller.call "getSwitchEnergy", @config.ain
                .then (energy) =>
                  @_setEnergy(Math.round(energy / 100.0) / 10.0)
        .catch (error) =>
          if not error.response?
            env.logger.error error.message
