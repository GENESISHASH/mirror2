# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
log = (x...) -> try console.log x...
logger = require './logger'

_ = require('wegweg')({
  globals: no
  shelljs: no
})

http = require 'http'
connect = require 'connect'
httpProxy = require 'http-proxy'

Proxy = require './proxy'

module.exports = class ProxyManager extends (require('events').EventEmitter)

  hosts: {}
  servers: {}

  constructor: (@opt={}) ->
    @hosts = @opt.hosts ? {}
    @opt.middleware ?= []
    @opt.globals ?= yes
    @opt.ascii ?= yes

    if @opt.globals
      process.on 'uncaughtException', (e) ->
        ignore = [
          'ECONNRESET'
          'hang up'
        ]

        for x in ignore
          return no if e.toString().includes(x)

        logger.error e

      process.env.NODE_TLS_REJECT_UNAUTHORIZED = 0

      require('http').globalAgent.maxSockets = 99999
      require('https').globalAgent.maxSockets = 99999

      @setMaxListeners 9999

    @setup_loggers()

  setup_loggers: ->
    @on 'error', (e) ->
      logger.error e

    request_events = [
      'request'
      'request_ignored'
      'request_delivered'
    ]

    for x in request_events
      do (x) =>
        @on x, (req) ->
          verb = 'info'
          verb = 'warn' if x is 'request_ignored'
          logger[verb] x, {
            url: req.url
            method: req.method
            proxy_host: req.proxy_host
          }

    spawn_events = [
      'proxy_manager_listening'
      'proxy_spawned'
    ]

    for x in spawn_events
      do (x) =>
        @on x, (data) ->
          logger.info x, data

  setup: (cb) ->
    if _.size(@hosts)
      for host,host_item of @hosts
        await @setup_proxy host, host_item, defer()

    @http_proxy = httpProxy.createProxyServer({
      ws: yes
      xfwd: yes
      autoRewrite: yes
      hostRewrite: yes
      protocolRewrite: 'http'
    })

    @http_proxy.on 'error', (e) =>
      @emit 'error', e

    app = connect()

    if @opt.middleware?.length
      app.use x for x in @opt.middleware

    app.use ((req,res,next) =>
      host = req.hostname ? req.headers?.host ? req.host ? no

      if !host
        return next new Error '`host` unparsable'

      if host.includes(':')
        host = host.split(':').shift()

      req.proxy_host = host

      @emit 'request', req

      if !(host_item = @hosts[host])
        @emit 'request_ignored', req
        req._code = 403
        return next new Error 'Forbidden'

      if !@servers[host]
        await @setup_proxy host, host_item, defer()

      request_opts = {
        target: 'http://127.0.0.1:' + @servers[host].port
      }

      @emit 'request_delivered', req
      @http_proxy.web req, res, request_opts, (e) ->
        return next e
    )

    app.use (err,req,res) =>
      @emit 'error', err
      return res.end(err.toString(),(req._code ? 500))

    @http = http.createServer(app)

    return cb null, yes

  setup_proxy: (host,opt,cb) ->
    opt.silent ?= yes

    @servers[host] = p = new Proxy opt

    await p.setup defer()
    p.listen()

    p.on 'error', (e) =>
      @emit 'error', e

    @emit 'child_spawned', {host:host,port:p.port,options:opt}

    return cb null, p.port

  listen: (port) ->
    @opt.port ?= port ? 7777
    @http.listen @opt.port
    @emit 'proxy_manager_listening', @opt

##
if !module.parent
  proxy_man = new ProxyManager({

    # middleware at the proxy manager level
    middleware: [((req,res,next) ->
      console.log "ProxyManager request: #{req.method} #{req.url}"
      next()
    )]

    hosts: {

      # local host to serve from
      'localhost': {

        # remote host to mirror
        host: 'stackoverflow.com'

        # middleware at the proxy instance level
        middleware: [((req,res,next) ->
          console.log "ProxyInstance request: #{req.method} #{req.url}"
          next()
        )]

        # synchronous source modifiers for text/html
        html_modifiers: [
          ((x) -> return x.replace('<title>','<title>(mirror-mirror) '))
        ]

        # html blob to append before `</head>` tags
        append_head: """
          <script>console.log('mirror-stackoverflow')</script>
        """
      }

      'proxy.com': {
        host: 'greatist.com'
        html_modifiers: [
          ((x) -> return x.replace('<title>','<title>(mirror-mirror) '))
        ]
        append_head: """
          <script>console.log('mirror-greatist.com')</script>
        """
      }

    }
  })

  proxy_man.setup ->
    proxy_man.listen 7777
    console.log ":7777"

