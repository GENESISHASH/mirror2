# mirror-mirror
a serious series of tubes

<img src="https://taky.s3.amazonaws.com/81gm232x02ou.svg">

# install

using [npm](https://npmjs.org)

```
npm i mirror-mirror --save
```

# example

``` coffeescript
mirror = require 'mirror-mirror'

proxy_man = new mirror.ProxyManager({
	hosts: {
		'localhost': {
			host: 'stackoverflow.com'
			script: """
				<script>alert('stackoverflow')</script>
			"""
		}
		'proxy.com': {
			host: 'greatist.com'
			script: """
				<script>alert('greatist.com')</script>
			"""
		}
	}
})

await proxy_man.setup defer()

proxy_man.listen 7777
log ":7777"
```


