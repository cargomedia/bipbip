bipbip
======
Agent to collect server metrics and send them to the [CopperEgg RevealMetrics](http://copperegg.com/) platform.
Plugins for different metrics available.
Will spawn a child process for every plugin and server you tell it to monitor.

Installation
------------
```
gem install bipbip
```

Configuration
-------------
Pass the path to your configuration file to `bipbip` using the `-c` command line argument.
```sh
bipbip -c /etc/bipbip/config.yml
```

The configuration file should list the services you want to collect data for:
```yml
logfile: /var/log/bipbip.log
loglevel: INFO
frequency: 15
include: services.d/

copperegg:
  apikey: YOUR_APIKEY

services:
  -
    plugin: memcached
    hostname: localhost
    port: 11211
  -
    plugin: mysql
    hostname: localhost
    port: 3306
    username: root
    password: root
  -
    plugin: redis
    hostname: localhost
    port: 6379
  -
    plugin: gearman
    hostname: localhost
    port: 4730
  -
    plugin: apache2
    url: http://localhost:80/server-status?auto
  -
    plugin: nginx
    url: http://localhost:80/server-status
  -
    plugin: network
  -
    plugin: php-apc
```

Include configuration
---------------------
In your configuration you can specify a directory to include service configurations from:
```
include: services.d/
```
This will include files from `/etc/bipbip/services.d/` and load them into the `services` configuration.

You could then add a file `/etc/bipbip/services.d/memcached.yml`:
```yml
plugin: memcached
hostname: localhost
port: 11211
```

Plugins source configuration
----------------------------
For some specific plugins you have to configure data source.

#### php-apc for apache2
This plugin works in thread of `apache2` worker process if `APC` for `PHP` is enabled.

To **configure** data source please use example:

Create file `/etc/apache2/conf.d/apc-status` with content:
```
Alias /apc-status /usr/local/bin/apc-status.php

<Files "/usr/local/bin/apc-status.php">
	Order deny,allow
	Deny from all
	Allow from all
</Files>

```
Create file `/usr/local/bin/apc-status.php` with content:
```php
<?php

$infoOpcode = @apc_cache_info('opcode', true);
$infoUser = @apc_cache_info('user', true);

echo json_encode(array(
	"opcode_mem_size" => (int) $infoOpcode['mem_size'],
	"user_mem_size"   => (int) $infoUser['mem_size'],
));

```

For **enable** configuration above you should reload apache e.g `/etc/init.d/apache2 reload`. 

For **test** you can e.g. `curl http//localhost:80/apc-status`