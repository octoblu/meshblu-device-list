request     = require 'superagent'
url         = require 'url'
_           = require 'lodash'
async       = require 'async'
MeshbluHttp = require 'browser-meshblu-http'
debug       = require('debug')('meshblu-device-list:device-list')

class DeviceList
  constructor: ({meshbluConfig,@tag}) ->
    @meshbluHttp = new MeshbluHttp meshbluConfig

  getList: (callback) =>
    @meshbluHttp.whoami (error, ogDevice) =>
      return callback error if error?
      {devices} = ogDevice
      return callback null, [] if _.isEmpty devices
      async.mapSeries devices, @processDevice, (error, devices) =>
        return callback error if error?
        callback null, _.compact devices

  processDevice: (device, callback) =>
    uuid = device if _.isString device
    {uuid} = device unless _.isString device

    @meshbluHttp.device uuid, (error, device) =>
      return callback error if error?
      return callback null unless device?
      @meshbluHttp.removeTokenByQuery uuid, {@tag}, (error) =>
        return callback error if error?
        @meshbluHttp.generateAndStoreToken uuid, {@tag}, (error, token) =>
          return callback error if error?
          newDevice = _.extend {}, device, {token}
          callback null, newDevice

module.exports = DeviceList
