var cluster = require('cluster');
var http = require('http');
var numCPUs = require('os').cpus().length;

if (cluster.isMaster) {
  for (var i = 0; i < numCPUs; i++) {
    cluster.fork();
  }

  cluster.on('exit', (worker, code, signal) => {
    console.log(`worker ${worker.process.pid} died`);
  });
} else {
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
}

