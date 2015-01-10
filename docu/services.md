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
- **username**
- **password**

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

### apache2
Configuration options:
- **url**: URL of apache's [mod_status](http://httpd.apache.org/docs/current/mod/mod_status.html) (e.g. `http://localhost:80/server-status?auto`).

### nginx
Configuration options:
- **url**: URL of nginx' [stub_status](http://nginx.org/en/docs/http/ngx_http_stub_status_module.html) (e.g. `http://localhost:80/server-status`).

### network
No configuration necessary.

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
No configuration necessary.