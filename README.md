<img src="https://taky.s3.amazonaws.com/31gm6glfzxkf.svg" height="225">

# mirror-mirror
`mirror-mirror` is a webserver project designed to reverse proxy and "mitm"
multiple sites. put it behind nginx and inject custom connect middleware into 
the proxy manager or specific proxy children using config options.

_magic mirror on the wall, who is the fairest one of all?_

# quick start

```
git clone https://github.com/punted/mirror-mirror
cd mirror-mirror
npm i
node usage.js
```

optionally for demo purposes, `echo "127.0.0.1 proxy.com" >> /etc/hosts`

open browser to `http://localhost:7777`

# usage

``` javascript
var mirror, server;

mirror = require('./');

server = new mirror.ProxyManager({
  hosts: {
    'localhost': {
      host: 'stackoverflow.com',
      html_modifiers: [
        (function(x) {
          return x.replace('<title>', '<title>(mirror-mirror) ');
        })
      ]
    },
    'proxy.com': {
      host: 'greatist.com',
      append_head: "<script>alert('greatist.com')</script>",
      html_modifiers: [
        (function(x) {
          return x.replace('<title>', '<title>(mirror-mirror) ');
        })
      ]
    }
  }
});

server.setup(function() {
  server.listen(7777);
  return console.log(":7777");
});
```

<img src="https://taky.s3.amazonaws.com/11gm75efdhkt.png" width=300>

## mirror.ProxyManager
### events
#### proxy_man.on('server_spawned',cb)
#### proxy_man.on('request',cb)
#### proxy_man.on('request_ignored',cb)
#### proxy_man.on('request_delivered',cb)
#### proxy_man.on('error',cb)

## mirror.Proxy
### events
#### proxy.on('request',cb)
#### proxy.on('request_delivered',cb)
#### proxy.on('error',cb)

