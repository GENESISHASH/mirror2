# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
log = (x...) -> try console.log x...

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
    @opt.port ?= 7777
    @hosts = @opt.hosts ? {}
    @opt.middleware = []

  setup: (cb) ->
    @http_proxy = httpProxy.createProxyServer({
      ws: yes
      xfwd: yes
      autoRewrite: yes
      hostRewrite: yes
      protocolRewrite: 'http'
    })

    app = connect()

    app.use ((req,res,next) =>
      host = req.hostname ? req.headers?.host ? req.host ? no

      if !host
        @emit 'error', new Error("Host unparsable")
        return res.end(null,500)

      if host.includes(':')
        host = host.split(':').shift()

      req.proxy_host = host
      @emit 'request', req

      if !(host_item = @hosts[host])
        @emit 'request_ignored', req
        return res.end "Forbidden", 403

      if !@servers[host]
        await @setup_proxy host, host_item, defer()

      request_opts = {
        target: 'http://127.0.0.1:' + @servers[host].port
      }

      @emit 'request_delivered', req
      @http_proxy.web(req,res,request_opts)
    )

    if @opt.middleware.length
      for x in @opt.middleware
        app.use x

    @http = http.createServer(app)

    @emit 'ready'
    return cb null, yes

  setup_proxy: (host,opt,cb) ->
    @servers[host] = p = new Proxy opt

    await p.setup defer()
    p.listen()

    @emit 'server_spawned', {host:host,port:p.port,options:opt}

    _.in '3 seconds', ->
      return cb null, p.port

  listen: ->
    @http.listen @opt.port

##
if !module.parent
  proxy_man = new ProxyManager({
    hosts: {
      'localhost': {
        host: 'stackoverflow.com'
        script: """
          <script>alert('stackoverflow')</script>
        """
      }
      'proxy.com': {
        host: 'greatist.com'
        script: """
          <script>alert('greatist.com')</script>
        """
      }
    }
  })

  proxy_man.on 'ready', ->
    log 'proxy_man_ready'

  await proxy_man.setup defer()

  proxy_man.listen 7777
  log ":7777"
##

