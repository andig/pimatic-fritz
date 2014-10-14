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
      options = @extend { url: @config.url }, @config.options

      fritz.getSessionID(@config.user, @config.password, options).then (sid) ->
        console.log("Fritz!Session ID: " + sid)
      #   fritz.getSwitchList sid
      #   .then (ains) ->
      #     console.log("Switches AIDs: " + ains)

      @framework.deviceManager.registerDeviceClass("FritzOutlet", {
        configDef: deviceConfigDef.FritzOutlet,
        createCallback: (config) =>
          return new FritzOutletDevice(config, this)
      })

    # Extend a source object with the properties of another object (shallow copy).
    extend: (object, properties) ->
      for key, val of properties
        object[key] = val
      return object

  class FritzOutletDevice extends env.devices.SwitchActuator
    # attributes
    attributes:
      current:
        description: "Current consumption"
        type: "number"
        unit: 'W'
      total:
        description: "Total consumption"
        type: "number"
        unit: 'W'

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

    _current: null
    _total: null

    # Initialize device by reading entity definition from middleware
    constructor: (@config, @plugin) ->
      @name = config.name
      @id = config.id

      # inherit middleware from plugin if not defined
      @config.url = @plugin.config.url unless @config.url

      super()

    # Get current value of last update in defined unit
    getCurrent: -> Promise.resolve(@_current)

    # Get total value of last update in defined unit
    getTotal: -> Promise.resolve(@_total)

    # Retuns a promise that is fulfilled when done.
    changeStateTo: (state) ->
      throw new Error "Function \"changeStateTo\" is not implemented!"

    # Returns a promise that will be fulfilled with the state
    getState: -> Promise.resolve(@_state)


  # ###Finally
  fritzPlugin = new FritzPlugin
  return fritzPlugin
