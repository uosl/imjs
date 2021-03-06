should = require 'should'
Fixture = require './lib/fixture'
{prepare, eventually} = require './lib/utils'

{Service} = Fixture
{unitTests, bothTests, integrationTests} = require './lib/segregation'

bothTests() && describe 'Service', ->

  unitTests() && describe 'new Service', ->

    it 'should make a new service', ->
      service = new Service root: 'foo'
      should.exist service
      service.should.be.an.instanceOf Service

    it 'should require at least a root property', ->
      (-> new Service).should.throw()

    it 'should not alter complete root urls', ->
      service = new Service root: 'http://localhost/intermine-test/service/'
      service.root.should.equal 'http://localhost/intermine-test/service/'

    it 'should ensure root urls have a trailing slash', ->
      service = new Service root: 'http://localhost/intermine-test/service'
      service.root.should.equal 'http://localhost/intermine-test/service/'

    it 'should deal with minimal root urls', ->
      service = new Service root: 'localhost/intermine-test'
      service.root.should.equal 'http://localhost/intermine-test/service/'

  integrationTests() && describe 'customHeaders', ->

    {headers} = new Fixture

    # By supplying an Authorization header with a bogus value we can prove
    # that headers are being overwritten because the authentication will fail.
    it 'override an authorization header', ->
      headers.fetchLists().then (res) ->
        res.should.startWith 'Invalid request authentication'
      , (err) ->
        err.message.trim().should.startWith 'Invalid request authentication.'

  unitTests() && describe '.connect', ->

    it 'should serve as an alias for "new Service"', ->
      service = Service.connect root: 'localhost/intermine-test'
      should.exist service
      service.should.be.an.instanceOf Service
      service.root.should.equal 'http://localhost/intermine-test/service/'

    it 'should check the arguments', ->
      (-> Service.connect()).should.throw /Invalid/

  # Note, the model is not re-requested, but because it is instantiated
  # from data, each service instance gets its own copy, so we test with
  # the summary fields instead, which can provide us with a strict identity
  # check (unlike the version and the release, which are primitives).

  integrationTests() && describe 'caching', ->

    describe 'useCache', ->

      {service} = new Fixture

      @beforeEach prepare service.fetchSummaryFields

      it 'should be true', ->
        service.useCache.should.be.true

      it 'should be inherited in child services', ->
        Service.connect(service).useCache.should.be.true

      it 'should mean things like the summary fields are cached', eventually (fa) ->
        Service.connect(service).fetchSummaryFields().then (fb) -> fb.should.equal fa

    describe 'flushCaches', ->
      {service} = new Fixture

      @beforeEach prepare service.fetchSummaryFields
      @afterEach Service.flushCaches

      it 'should mean we get fresh objects', eventually (fa) ->
        Service.flushCaches()
        Service.connect(service).fetchSummaryFields().then (fb) -> fb.should.not.equal fa
