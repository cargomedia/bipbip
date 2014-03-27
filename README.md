bipbip [![Build Status](https://travis-ci.org/cargomedia/bipbip.png)](https://travis-ci.org/cargomedia/bipbip)
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

storages:
  -
    name: copperegg
    api_key: YOUR_APIKEY

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
    plugin: resque
    hostname: localhost
    port: 6379
    database: 10
    namespace: resque-prefix
    frequency: 60
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
    url: http://localhost:80/apc-status
  -
    plugin: fastcgi-php-fpm
    host: localhost
    port: 9000
    path: /fpm-status
  -
    plugin: fastcgi-php-apc
    host: localhost
    port: 9000
  -
    plugin: fastcgi-php-opcache
    host: localhost
    port: 9000
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

You can also set an override frequency per service in the main config or in these included configs.

Plugins
-------
#### fastcgi-php-fpm
Requires the `cgi-fcgi` program (debian package: `libfcgi0ldbl`).

#### fastcgi-php-apc
Requires the `cgi-fcgi` program (debian package: `libfcgi0ldbl`).

#### fastcgi-php-opcache
Requires the `cgi-fcgi` program (debian package: `libfcgi0ldbl`).

#### php-apc
To collect `APC` stats of your apache process, please install the following script.

Create file `/usr/local/bin/apc-status.php` with content of `data/apc-status.php`.

Create apache config `/etc/apache2/conf.d/apc-status` with content:
```
Alias /apc-status /usr/local/bin/apc-status.php

<Files "/usr/local/bin/apc-status.php">
	Order deny,allow
	Deny from all
	Allow from 127.0.0.1
</Files>
```

Then set the `url`-configuration for the plugin to where the script is being served, e.g. `http//localhost:80/apc-status`.

Custom external plugins
-----------------------
Additional plugins can be created as independent gems.
They should include a class `Plugin::MyPlugin` in the `BipBip` module extending `Plugin`.
On that class the functions `metrics_schema` and `monitor` should be implemented.

For a complete example see [cargomedia/bipbip-random-example](https://github.com/cargomedia/bipbip-random-example).
