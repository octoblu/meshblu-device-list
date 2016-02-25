shmock = require '@octoblu/shmock'
DeviceList = require '../src/device-list'

describe 'DeviceList', ->
  beforeEach ->
    @meshblu = shmock 0xd00d

  afterEach (done) ->
    @meshblu.close => done()

  describe 'when constructed with valid meshbluConfig', ->
    beforeEach ->
      meshbluConfig =
        server: 'localhost'
        port: 0xd00d
        uuid: 'some-uuid'
        token: 'some-token'

      @sut = new DeviceList {meshbluConfig, tag: 'remove-this-tag'}

    describe 'when the device has multiple devices', ->
      beforeEach (done) ->
        auth = new Buffer('some-uuid:some-token').toString('base64')
        @whoami = @meshblu
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{auth}"
          .reply 200,
            uuid: 'some-uuid',
            devices: [
              {uuid:'hello-uuid'}
              {uuid:'howdy-uuid'}
              {uuid:'cheers-uuid'}
            ]

        @firstDeviceGet = @meshblu
          .get '/v2/devices/hello-uuid'
          .set 'Authorization', "Basic #{auth}"
          .reply 200, device: uuid: 'hello-uuid'

        @firstDeviceRevoke = @meshblu
          .delete '/devices/hello-uuid/tokens'
          .query tag: 'remove-this-tag'
          .set 'Authorization', "Basic #{auth}"
          .reply 200

        @firstDeviceGenerate = @meshblu
          .post '/devices/hello-uuid/tokens'
          .set 'Authorization', "Basic #{auth}"
          .send tag: 'remove-this-tag'
          .reply 200, token: 'generated-hello-token'

        @secondDeviceGet = @meshblu
          .get '/v2/devices/howdy-uuid'
          .set 'Authorization', "Basic #{auth}"
          .reply 200, device: uuid: 'howdy-uuid'

        @secondDeviceRevoke = @meshblu
          .delete '/devices/howdy-uuid/tokens'
          .query tag: 'remove-this-tag'
          .set 'Authorization', "Basic #{auth}"
          .reply 200

        @secondDeviceGenerate = @meshblu
          .post '/devices/howdy-uuid/tokens'
          .set 'Authorization', "Basic #{auth}"
          .send tag: 'remove-this-tag'
          .reply 200, token: 'generated-howdy-token'

        @thirdDeviceGet = @meshblu
          .get '/v2/devices/cheers-uuid'
          .set 'Authorization', "Basic #{auth}"
          .reply 404, {}

        @sut.getList (error, @devices) => done error

      it 'should run whoami', ->
        @whoami.done()

      it 'should return full devices array', ->
        expect(@devices).to.deep.equal [
          {uuid: 'hello-uuid', token: 'generated-hello-token'}
          {uuid: 'howdy-uuid', token: 'generated-howdy-token'}
        ]

      describe 'first device', ->
        it 'should get the device in the devices array', ->
          @firstDeviceGet.done()

        it 'should revoke the token by query', ->
          @firstDeviceRevoke.done()

        it 'should generate a token', ->
          @firstDeviceGenerate.done()

      describe 'second device', ->
        it 'should get the device in the devices array', ->
          @secondDeviceGet.done()

        it 'should revoke the token by query', ->
          @secondDeviceRevoke.done()

        it 'should generate a token', ->
          @secondDeviceGenerate.done()

      describe 'third device', ->
        it 'should get the device', ->
          @thirdDeviceGet.done()

    describe 'when the device has one device in string style', ->
      beforeEach (done) ->
        auth = new Buffer('some-uuid:some-token').toString('base64')
        @whoami = @meshblu
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{auth}"
          .reply 200,
            uuid: 'some-uuid',
            devices: [
              'hello-uuid'
            ]

        @firstDeviceGet = @meshblu
          .get '/v2/devices/hello-uuid'
          .set 'Authorization', "Basic #{auth}"
          .reply 200, device: uuid: 'hello-uuid'

        @firstDeviceRevoke = @meshblu
          .delete '/devices/hello-uuid/tokens'
          .query tag: 'remove-this-tag'
          .set 'Authorization', "Basic #{auth}"
          .reply 200

        @firstDeviceGenerate = @meshblu
          .post '/devices/hello-uuid/tokens'
          .set 'Authorization', "Basic #{auth}"
          .send tag: 'remove-this-tag'
          .reply 200, token: 'generated-hello-token'

        @sut.getList (error, @devices) => done error

      it 'should run whoami', ->
        @whoami.done()

      it 'should return full devices array', ->
        expect(@devices).to.deep.equal [
          {uuid: 'hello-uuid', token: 'generated-hello-token'}
        ]

      it 'should get the device in the devices array', ->
        @firstDeviceGet.done()

      it 'should revoke the token by query', ->
        @firstDeviceRevoke.done()

      it 'should generate a token', ->
        @firstDeviceGenerate.done()
