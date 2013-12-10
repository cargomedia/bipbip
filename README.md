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
bipbip -c /etc/bipbip/bipbip.yml
```

The configuration file should list the services you want to collect data for:
```yml
loglevel: INFO
include: services.d/

copperegg:
  apikey: YOUR_APIKEY
  frequency: 15

services:
  -
    plugin: Memcached
    hostname: localhost
    port: 11211
  -
    plugin: Mysql
    hostname: localhost
    port: 3306
    username: root
    password: root
  -
    plugin: Redis
    hostname: localhost
    port: 6379
  -
    plugin: Gearman
    hostname: localhost
    port: 4730
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
plugin: Memcached
hostname: localhost
port: 11211
```
