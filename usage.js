var mirror, server;

mirror = require('./');

var _ = require('wegweg')()
log(mirror)

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
