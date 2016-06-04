# mirror-mirror
a serious series of tubes

<img src="https://taky.s3.amazonaws.com/31gm6glfzxkf.svg" height="225">

# usage

```
git clone https://github.com/punted/mirror-mirror
cd mirror-mirror
npm i
node test.js
```

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
## mirror.Proxy

