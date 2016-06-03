# mirror-mirror
a serious series of tubes

<img src="https://taky.s3.amazonaws.com/81gm232x02ou.svg" height="225">

# install

using [npm](https://npmjs.org)

```
npm i mirror-mirror --save
```

# example

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


