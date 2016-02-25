request = require 'superagent'
url     = require 'url'
_       = require 'lodash'
async   = require 'async'
debug   = require('debug')('meshblu-device-list:device-list')

class DeviceList
  constructor: ({meshbluConfig,@tag}) ->
    options = _.extend port: 443, server: 'meshblu.octoblu.com', meshbluConfig
    {@uuid, @token, @server, @port, @protocol} = options
    @protocol = null if @protocol == 'websocket'
    try @port = parseInt @port
    @protocol ?= 'http'
    @protocol = 'https' if @port == 443

  generateAndStoreToken: (uuid, callback) =>
    debug 'generateAndStoreToken'
    request
      .post @_url "/devices/#{uuid}/tokens"
      .auth @uuid, @token
      .send {@tag}
      .end (error, response) =>
        debug 'generateAndStoreToken response', response.status
        return callback new Error 'Invalid Response Code' unless response.ok
        return callback new Error 'Invalid Response' if _.isEmpty response.body
        callback null, response.body.token

  getList: (callback) =>
    @whoami (error, ogDevice) =>
      return callback error if error?
      {devices} = ogDevice
      return callback null, [] if _.isEmpty devices
      async.mapSeries devices, @processDevice, (error, devices) =>
        return callback error if error?
        callback null, _.compact devices

  getDevice: (uuid, callback) =>
    debug 'getDevice'
    request
      .get @_url "/v2/devices/#{uuid}"
      .auth @uuid, @token
      .end (error, response) =>
        debug 'getDevice response', response.status
        return callback null if response.notFound
        return callback new Error 'Invalid Response Code' unless response.ok
        return callback new Error 'Invalid Response' if _.isEmpty response.body
        callback null, response.body.device

  processDevice: (device, callback) =>
    uuid = device if _.isString device
    {uuid} = device unless _.isString device

    @getDevice uuid, (error, device) =>
      return callback error if error?
      return callback null unless device?
      @removeTokenByQuery uuid, (error) =>
        return callback error if error?
        @generateAndStoreToken uuid, (error, token) =>
          return callback error if error?
          newDevice = _.extend {}, device, {token}
          callback null, newDevice

  removeTokenByQuery: (uuid, callback) =>
    debug 'removeTokenByQuery'
    request
      .del @_url "/devices/#{uuid}/tokens"
      .query {@tag}
      .auth @uuid, @token
      .end (error, response) =>
        debug 'removeTokenByQuery response', response.status
        return callback new Error 'Invalid Response Code' unless response.ok
        callback null

  whoami: (callback) =>
    debug 'whoami'
    request
      .get @_url '/v2/whoami'
      .auth @uuid, @token
      .end (error, response) =>
        debug 'whoami response', response.status
        return callback new Error 'Invalid Response Code' unless response.ok
        return callback new Error 'Invalid Device' if _.isEmpty response.body
        callback null, response.body

  _url: (pathname) =>
    url.format {@protocol, hostname:@server, @port, pathname}

module.exports = DeviceList
