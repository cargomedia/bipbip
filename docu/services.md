Service Plugins
===============

### memcached
Configuration options:
- **hostname**
- **port**

### mysql
Configuration options:
- **hostname**
- **port**
- **username**
- **password**

### mongodb
Configuration options:
- **hostname**
- **port**
- **user** (optional)
- **password** (optional)
- **database** (optional)
- **slow_query_threshold** (optional): Defaults to `0` millis (meaning it will count all slow queries as configured by [`slowOpThresholdMs`](http://docs.mongodb.org/manual/reference/configuration-options/#operationProfiling.slowOpThresholdMs)).

### redis
Configuration options:
- **hostname**
- **port**

### resque
- **hostname** (optional): Will default to `localhost`.
- **port** (optional): Will default to `6369`.
- **database**
- **namespace**

### gearman
Configuration options:
- **hostname**
- **port**
- **persistence** (optional): Allows to read additional stats like: jobs count by priority. It support `mysql` adapter only.
- **mysql_host** (optional): Used only with `persistance=mysql`. By default to `localhost`.
- **mysql_port** (optional): Used only with `persistance=mysql`. By default to `3306`.
- **mysql_username** (optional): Used only with `persistance=mysql`. By default to `root`.
- **mysql_password** (optional): Used only with `persistance=mysql`. By default to `nil`.
- **mysql_database** (optional): Used only with `persistance=mysql`. By default to `gearman`.

### apache2
Configuration options:
- **url**: URL of apache's [mod_status](http://httpd.apache.org/docs/current/mod/mod_status.html) (e.g. `http://localhost:80/server-status?auto`).

### nginx
Configuration options:
- **url**: URL of nginx' [stub_status](http://nginx.org/en/docs/http/ngx_http_stub_status_module.html) (e.g. `http://localhost:80/server-status`).

### network
Configuration options:
- **exclude_interfaces** (optional): Regex list of network interfaces to exclude (Default: `[ /lo/, /bond/, /vboxnet/ ]`).

### monit
Configuration options:
- **hostname** (optional): Defaults to `localhost`.
- **port** (optional): Defaults to `2812`.
- **ssl** (optional): Whether to use SSL for the connection. Defaults to `false`.
- **auth** (optional): Whether to use authentication. Defaults to `false`.
- **username** (optional)
- **password** (optional)

### php-apc
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

### fastcgi-php-fpm
Requires the `cgi-fcgi` program to be installed (Debian package: `libfcgi0ldbl`).

Configuration options:
- **host**
- **port**
- **path**: Path to php-fpm's status page (`pm.status_path`).

### fastcgi-php-apc
Collect *APC* metrics from a fastcgi server (e.g. php-fpm).

The plugin connects to the fastcgi server requesting exection of the [`apc-status.php`](/data/apc-status.php) script in bipbip's installation directory.
Requires the `cgi-fcgi` program to be installed (Debian package: `libfcgi0ldbl`).

Configuration options:
- **host**
- **port**

### fastcgi-php-opcache
Collect *opcache* metrics from a fastcgi server (e.g. php-fpm).

The plugin connects to the fastcgi server requesting exection of the [`php-opcache-status.php`](/data/php-opcache-status.php) script in bipbip's installation directory.
Requires the `cgi-fcgi` program to be installed (Debian package: `libfcgi0ldbl`).

Configuration options:
- **host**
- **port**

### log-parser
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

### postfix
No configuration necessary.

### elasticsearch
Configuration options:
- **hostname**
- **port**

### puppet
- **lastrunfile** (optional): Path of `last_run_summary.yaml`. Defaults to `/var/lib/puppet/state/last_run_summary.yaml`.

### command
Configuration options:
- **command** Command to execute. Needs to return JSON parsable string (e.g. `ruby -e 'puts "{\"file_count\": 5}"'`)

First run of plugin will execute command and parse results to learn the schema. There are two basic types of metric entry: `simple`, `advanced` (see details below).

#### Schema examples
In `simple` metric entry mode the plugin expects data in format like below
```json
{
  "metric1": 12,
  "metric2": true
}
```
Metric type will be set to `gauge` by default.

In `advanced` metric entry mode the plugin expects data as `hash` with metric `type` and `unit` defined.
```json
{
  "metric1": {"value": 18, "type": "[gauge|counter]", "unit": "<unit>"},
  "metric2": {"value": false, "type": "[gauge|counter]", "unit": "<unit>"}
}
```

There is also possibility to mix metric entries of type `simple` and `advanced`
```json
{
  "metric1": {"value": 18, "type": "[gauge|counter]", "unit": "<unit>"},
  "metric2": 12,
  "metric3": {"value": false, "type": "[gauge|counter]", "unit": "<unit>"},
  "metric4": true
}
```

Boolean values `true`, `false` will be replaced with `1`, `0` for both modes.

### socket-redis
Configuration options:
- **url**: URL of `socket-redis` [status](https://github.com/cargomedia/socket-redis#status-request). Defaults to `http://localhost:8085/status`

### coturn
Configuration options:
- **hostname** (optional): Will default to `localhost`.
- **port** (optional): Defaults to `5766`.

### janus-rtpbroadcast
Configuration options:
- **url** (optional): Will default to `http://localhost:8088/janus`.

### janus-audioroom
Configuration options:
- **url** (optional): Will default to `http://localhost:8088/janus`.


### systemd-unit
Configuration options:
- **unit_name**: Name of the main systemd unit. 
