log = (x...) -> try console.log x...

_ = require('wegweg')({
  globals: no
  shelljs: no
})

winston = require 'winston'

logger = new winston.Logger({
  exitOnError: no
  transports: [
    new (winston.transports.Console)({
      timestamp: yes
      colorize: yes
    }),
  ]
})

module.exports = logger

