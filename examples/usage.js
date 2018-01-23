var mirror, server;

mirror = require('./../');

server = new mirror.ProxyManager({
  hosts: {
    'localhost': {
      host: 'crowdsale.storiqa.com',
      enable_ssl: true,
      silent: false,
      html_modifiers: [
        (function(x) {
          return x.replace('<title>', '<title>(mirror-mirror) ');
        })
      ]
    },
    'greatist.com': {
      host: 'papergangster.com',
      enable_ssl: true,
      silent: true,
      html_modifiers: [
        (function(x) {
          return x.replace('<title>','<title>lol dongs ');
        })
      ]
    }
  }
});

server.setup(function() {
  server.listen(7777);
  return console.log(":7777");
});
