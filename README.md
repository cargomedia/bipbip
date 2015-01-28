bipbip [![Build Status](https://travis-ci.org/cargomedia/bipbip.png)](https://travis-ci.org/cargomedia/bipbip)
======
Agent to collect server metrics and send them to the [CopperEgg RevealMetrics](http://copperegg.com/) platform.
Plugins for different metrics available.

Installation
------------
```
gem install bipbip
```

There's a [puppet module for Debian](https://github.com/cargomedia/puppet-packages/tree/master/modules/bipbip) available to install *bipbip* as a system daemon.

### Configuration
Pass the path to your configuration file to `bipbip` using the `-c` command line argument.
```sh
bipbip -c /etc/bipbip/config.yml
```

Example with CopperEgg as a storage and service plugins for *memcached* and *mysql* configured:
```yml
logfile: /var/log/bipbip.log
loglevel: INFO
frequency: 15
include: services.d/

storages:
  -
    name: copperegg
    api_key: <YOUR_APIKEY>

services:
  -
    plugin: memcached
    hostname: localhost
    port: 11211
  -
    plugin: mysql
    hostname: localhost
    port: 3306
```

Configuration options:
- **logfile** (optional): Path to log file. If not provided will log to `STDOUT`.
- **loglevel** (optional): One of [Logger's levels](http://www.ruby-doc.org/stdlib-2.1.0/libdoc/logger/rdoc/Logger.html). Defaults to `INFO`.
- **frequency** (optional): How often to measure metrics (in seconds). Defaults to `60`.
- **include** (optional): Optional directory where to look for *service plugin configurations* (relative to config file).
- **storage**: List of storages to send data to.
- **services**: List of service plugins from which to gather metrics.

The `include` directive allows to set a directory from which to load additional *service plugin* configurations. The above example could also be structured with multiple files:
```
.
|-- config.yml
`-- services.d
    |-- memcached.yml
    `-- mysql.yml
```
Where `memcached.yml` would contain:
```yml
plugin: memcached
hostname: localhost
port: 11211
```

The configuration for each *service plugin* is described further down.
The following options are available for all plugins:
- `frequency`: Override the global measurement frequency.
- `metric_group`: Use a metric group name different from the plugin's name. Useful when using the same plugin twice.

Storages
--------
Currently *bipbip* has only one storage available, but more could be added.

### copperegg
Send metrics to [CopperEgg](http://copperegg.com/)'s custom metrics API (*RevealMetrics*).

Configuration options:
- **api_key**: Your API key

Service Plugins
---------------
These service plugins ship with bipbip:
- memcached
- mysql
- mongodb
- redis
- resque
- gearman
- apache2
- nginx
- network
- monit
- php-apc
- fastcgi-php-fpm
- fastcgi-php-apc
- fastcgi-php-opcache
- log-parser
- postfix
- elasticsearch
- puppet
- command
- socket-redis

Please refer to [/docu/services.md](/docu/services.md) for information about the individual plugins and their configuration options.

Custom Service Plugins
----------------------
Additional service plugins can be created as independent gems.
They should include a class `Plugin::MyPlugin` in the `BipBip` module extending `Plugin`.
On that class the functions `metrics_schema` and `monitor` should be implemented.

For a complete example see [cargomedia/bipbip-random-example](https://github.com/cargomedia/bipbip-random-example).

Development
-----------
Start and provision the development-VM with vagrant, then log in:
```
vagrant up
vagrant ssh
```

You can then run `bipbip` from within the mounted projected root directory:
```
/vagrant/bin/bipbip
```
