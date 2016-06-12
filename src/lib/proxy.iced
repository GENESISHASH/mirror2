# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
log = (x...) -> try console.log x...
logger = require './logger'

_ = require('wegweg')({
  globals: no
  shelljs: no
})

http = require 'http'
harmon = require 'harmon'
connect = require 'connect'
mitm = require 'http-mitm-proxy'
httpProxy = require 'http-proxy'

module.exports = class Proxy extends (require('events').EventEmitter)
  _used_ports: []

  constructor: (@opt={}) ->
    @opt.host ?= "stackoverflow.com"
    @opt.silent ?= no
    @setup_loggers() unless @opt.silent

  setup: (cb) ->
    if !@opt.proxy_port
      await @_find_port defer e,open_port
      @opt.proxy_port = open_port
      @_used_ports.push open_port

    if !@opt.port
      await @_find_port defer e,open_port
      @opt.port = open_port
      @_used_ports.push open_port

    @port = @opt.port
    @proxy_port = @opt.proxy_port

    @setup_proxy()
    @setup_http()

    cb null, @opt

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
          }

    spawn_events = [
      'proxy_listening'
    ]

    for x in spawn_events
      do (x) =>
        @on x, (data) ->
          logger.info x, data

  setup_proxy: ->
    @proxy = mitm()
    @proxy.use mitm.gunzip

    @proxy.onRequest (ctx,cb) =>
      @emit 'request', ctx.clientToProxyRequest

      chunks = []
      ctx.isSSL = false

      if @opt.enable_ssl
        ctx.isSSL = true
        ctx.proxyToServerRequestOptions.agent = @proxy.httpsAgent
        ctx.proxyToServerRequestOptions.port = '443'


      ctx.proxyToServerRequestOptions.headers['accept-encoding'] = 'gzip'

      ctx.onResponseData (ctx,chunk,next) =>
        chunks.push(chunk)
        return next()

      ctx.onResponseEnd (ctx,next) =>
        body = Buffer.concat(chunks)
        bulk = body.toString()

        url = ctx.clientToProxyRequest.url

        _end = ((s) ->
          ctx.proxyToClientResponse.write(s)
          return next()
        )

        return _end(body) if !bulk.includes('</head>')

        content_type = ctx.serverToProxyResponse.headers?['content-type'] ? 'none'
        return _end(body) if !(content_type.indexOf('text/html') > -1)

        if @opt.append_head
          bulk = bulk.replace(/<\/head>/g,@opt.append_head + '</head>')

        if @opt.html_modifiers?.length
          for modifier in @opt.html_modifiers
            bulk = modifier(bulk)

        return _end(bulk)

      return cb()

  setup_http: ->
    @http_proxy = httpProxy.createProxyServer({
      ws: yes
      xfwd: yes
      autoRewrite: yes
      hostRewrite: yes
      secure: no
    })

    @http_proxy.on 'error', (e) =>
      @emit 'error', e

    # harmon rewriters for relative src/href values
    _rewrite = (attr_name,node) =>
      attr = node.getAttribute attr_name
      return if !attr?.includes?(@opt.host)

      new_value = attr

      for x in ['https://','http://','//']
        if new_value.startsWith(x + @opt.host)
          new_value = new_value.substr((x + @opt.host).length)

      node.setAttribute attr_name, new_value

    selects = [{
      query: 'a, link'
      func: ((node) =>
        _rewrite('href',node)
      )
    },{
      query: 'img, script'
      func: ((node) =>
        _rewrite('src',node)
      )
    }]

    if @opt.harmon_selects?.length
      selects = selects.concat(@opt.harmon_selects)

    app = connect()
    app.use harmon([],selects,yes)

    if @opt.middleware?.length
      app.use x for x in @opt.middleware

    app.use ((req,res,next) =>
      req.headers.host = @opt.host
      request_opts = {
        target: 'http://127.0.0.1:' + @opt.proxy_port
      }
      @emit 'request_delivered', req
      @http_proxy.web req, res, request_opts, (e) ->
        return next e
    )

    app.use (err,req,res) =>
      @emit 'error', err
      return res.end(err.toString(),(req._code ? 500))

    @http = http.createServer(app)

  listen: ->
    @proxy.listen {
      port: @opt.proxy_port
    }
    @http.listen @opt.port
    @emit 'proxy_listening', @opt

  _find_port: (cb) ->
    @portrange ?= 45032

    while @portrange in @_used_ports
      @portrange += 1

    port = @portrange

    @portrange += 1

    server = require('net').connect port, =>
      server.destroy()
      @_find_port cb

    server.on 'error', ->
      return cb null, port

###
if !module.parent
  p = new Proxy {
    host: 'greatist.com'
    port: 8009
  }

  await p.setup defer()

  p.listen()
  log ":8009"
###
