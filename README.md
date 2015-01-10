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

#### copperegg
Send metrics to [CopperEgg](http://copperegg.com/)'s custom metrics API (*RevealMetrics*).

Configuration options:
- **api_key**: Your API key

Service Plugins
---------------
#### memcached
Configuration options:
- **hostname**
- **port**

#### mysql
Configuration options:
- **hostname**
- **port**
- **username**
- **password**

#### mongodb
Configuration options:
- **hostname**
- **port**
- **username**
- **password**

#### redis
Configuration options:
- **hostname**
- **port**

#### resque
- **hostname** (optional): Will default to `localhost`.
- **port** (optional): Will default to `6369`.
- **database**
- **namespace**

#### gearman
Configuration options:
- **hostname**
- **port**

#### apache2
Configuration options:
- **url**: URL of apache's [mod_status](http://httpd.apache.org/docs/current/mod/mod_status.html) (e.g. `http://localhost:80/server-status?auto`).

#### nginx
Configuration options:
- **url**: URL of nginx' [stub_status](http://nginx.org/en/docs/http/ngx_http_stub_status_module.html) (e.g. `http://localhost:80/server-status`).

#### network
No configuration necessary.

#### monit
Configuration options:
- **hostname** (optional): Defaults to `localhost`.
- **port** (optional): Defaults to `2812`.
- **ssl** (optional): Whether to use SSL for the connection. Defaults to `false`.
- **auth** (optional): Whether to use authentication. Defaults to `false`.
- **username** (optional)
- **password** (optional)

#### php-apc
Collect *APC* metrics from a web server (e.g. apache).

Requires the script [`apc-status.php`](/data/apc-status.php) to be served by the web server.
An appropriate apache configuration would look something like this:
```
Alias /apc-status /usr/local/bin/apc-status.php

<Files "/usr/local/bin/apc-status.php">
	Order deny,allow
	Deny from all
	Allow from 127.0.0.1
</Files>
```

Configuration options:
- **url**: URL of the APC status script (e.g. `http://localhost:80/apc-status`).

#### fastcgi-php-fpm
Requires the `cgi-fcgi` program to be installed (Debian package: `libfcgi0ldbl`).

Configuration options:
- **host**
- **port**
- **path**: Path to php-fpm's status page (`pm.status_path`).

#### fastcgi-php-apc
Collect *APC* metrics from a fastcgi server (e.g. php-fpm).

The plugin connects to the fastcgi server requesting exection of the [`apc-status.php`](/data/apc-status.php) script in bipbip's installation directory.
Requires the `cgi-fcgi` program to be installed (Debian package: `libfcgi0ldbl`).

Configuration options:
- **host**
- **port**

#### fastcgi-php-opcache
Collect *opcache* metrics from a fastcgi server (e.g. php-fpm).

The plugin connects to the fastcgi server requesting exection of the [`php-opcache-status.php`](/data/php-opcache-status.php) script in bipbip's installation directory.
Requires the `cgi-fcgi` program to be installed (Debian package: `libfcgi0ldbl`).

Configuration options:
- **host**
- **port**

#### log-parser
Collect the number of occurences of strings in log files. Useful for example to measure *oom_killer* activity.

Configuration options:
- **path**: Path of log file
- **matchers**: An array of matchers to look for, each with a `name` and a `regexp`.

Example configuration:
```
plugin: log-parser
path: /var/log/syslog
matchers:
 -
  name: oom_killer
  regexp: 'invoked oom_killer'
 -
  name: segfault
  regexp: segfault
```

#### postfix
No configuration necessary.

#### elasticsearch
Configuration options:
- **hostname**
- **port**

#### puppet
No configuration necessary.

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
