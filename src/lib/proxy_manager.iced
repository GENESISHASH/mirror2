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
    @opt.port ?= 7777
    @hosts = @opt.hosts ? {}
    @opt.middleware = []

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

    app.use (err,req,res) ->
      @emit 'error', err
      return res.end(err.toString(),(req._code ? 500))

    @http = http.createServer(app)

    return cb null, yes

  setup_proxy: (host,opt,cb) ->
    @servers[host] = p = new Proxy opt

    await p.setup defer()
    p.listen()

    @emit 'server_spawned', {host:host,port:p.port,options:opt}

    return cb null, p.port

  listen: ->
    @http.listen @opt.port

##
if !module.parent
  proxy_man = new ProxyManager({
    hosts: {
      'localhost': {
        host: 'stackoverflow.com'
        append_head: """
          <script>alert('stackoverflow')</script>
        """
        html_modifiers: [
          ((x) -> return x.replace('<title>','<title>(mirror-mirror) '))
        ]
      }
      'proxy.com': {
        host: 'greatist.com'
        append_head: """
          <script>alert('greatist.com')</script>
        """
        html_modifiers: [
          ((x) -> return x.replace('<title>','<title>(mirror-mirror) '))
        ]
      }
    }
  })

  proxy_man.on 'error', (e) ->
    log 'error'
    log e.toString()

  proxy_man.on 'server_spawned', (data) ->
    log /server spawned/
    log data

  await proxy_man.setup defer()

  proxy_man.listen 7777
  log ":7777"
##

