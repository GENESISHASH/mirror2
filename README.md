<img src="https://taky.s3.amazonaws.com/31gm6glfzxkf.svg" height="225">

# mirror-mirror
a serious series of tubes

# quick start

```
git clone https://github.com/punted/mirror-mirror
cd mirror-mirror
npm i
node usage.js
```

open browser to `http://localhost:7777`

# usage

``` javascript
var mirror, server;

mirror = require('./');

server = new mirror.ProxyManager({
  hosts: {
    'localhost': {
      host: 'stackoverflow.com',
      script: "<script>alert(1)</script>"
    },
    'proxy.com': {
      host: 'greatist.com',
      script: "<script>alert(2)</script>"
    }
  }
});

server.setup(function() {
  server.listen(7777);
  return console.log(":7777");
});
```

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

