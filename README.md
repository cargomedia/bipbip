copperegg_agents
================
Agent to collect server metrics and send them to the [CopperEgg RevealMetrics](http://copperegg.com/) platform.
Plugins for different metrics available in the `plugin/`-directory.
Will spawn a child process for every plugin and server you tell it to monitor.

Configure and run
-----------------
Pass the path to your configuration file to `copperegg_agents` using the `-c` command line argument.
```sh
copperegg_agents -c /etc/copperegg_agents.yml
```

The configuration file should list the services you want to collect for, and the servers for each of them, e.g.:
```yml
loglevel: "INFO"
copperegg:
  apikey: "YOUR_APIKEY"
  frequency: 15
  services:
  - memcached
  - apache
memcached:
  name: "Memcached"
  servers:
  -
    hostname: "localhost"
    port: 11211
apache:
  name: "Apache"
  servers:
  -
    url: "http://localhost/server_status"
  -
    url: "http://localhost:8080/server_status"
```
