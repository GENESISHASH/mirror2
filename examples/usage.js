var mirror, server;

mirror = require('./../');

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
