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

class ProxyManager

  hosts: {}
  servers: {}

  constructor: (@opt={}) ->
    @opt.port ?= 7777
    @hosts = @opt.hosts ? {}

  refresh_hosts: (hosts) ->
    @hosts = hosts

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

      if host.includes(':')
        host = host.split(':').shift()

      if !(host_item = @hosts[host])
        return res.end "Forbidden", 403

      if !@servers[host]
        await @setup_proxy host, host_item, defer()

      request_opts = {
        target: 'http://127.0.0.1:' + @servers[host].port
      }

      @http_proxy.web(req,res,request_opts)
    )

    @http = http.createServer(app)
    return cb null, yes

  setup_proxy: (host,opt,cb) ->
    @servers[host] = p = new Proxy opt

    await p.setup defer()
    p.listen()

    return cb null, p.port

  listen: ->
    @http.listen @opt.port

###
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

  await proxy_man.setup defer()

  proxy_man.listen 7777
  log ":7777"
###

