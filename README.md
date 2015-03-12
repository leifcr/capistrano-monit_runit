# Capistrano - Monit and Runit helpers

This libary is a helper library for capistrano tasks that setup [runit](smarden.org/runit/) and [monit](http://mmonit.com/monit) for various services.

Note: This has been updated to support Capistrano >= 3.4. If you still use Capistrano 2.x, see the capistrano2 branch

## Versioning

This gem stays at 3.x for capistrano 3, as it seems logical.

## Sudoing

The setup process requires sudo on some files and folders upon creation.

You must either do the job manually or add this to the sudoers file:

```
Cmnd_Alias RUNITCAPISTRANO = ,
deploy  ALL=NOPASSWD: /bin/chmod u+x /etc/sv/*
deploy  ALL=NOPASSWD: /bin/chmod g+x /etc/sv/*
deploy  ALL=NOPASSWD: /bin/chown deploy\:root /etc/sv/*
deploy  ALL=NOPASSWD: /bin/chown -R deploy\:root /etc/sv/*
deploy  ALL=NOPASSWD: /bin/chown -R deploy\:root /etc/service/*
deploy  ALL=NOPASSWD: /bin/chown -R syslog\:syslog /var/log/service*
deploy  ALL=NOPASSWD: /bin/mkdir -p /etc/service/*
deploy  ALL=NOPASSWD: /bin/mkdir /etc/service/*
deploy  ALL=NOPASSWD: /bin/mkdir -p /var/log/service*
deploy  ALL=NOPASSWD: /bin/mkdir -p /etc/sv/*
deploy  ALL=NOPASSWD: /bin/mkdir /etc/sv/*
deploy  ALL=NOPASSWD: /bin/rm -rf /etc/service/*

```
,/bin/chown myuser:mygroup /var/www/html/*,/bin/chmod 755 /var/www/html2/myapp/*.txt


## Services for Monit and Runit

Services created:

* _[capistrano-puma](https://github.com/leifcr/capistrano-puma)_ for [Puma](http://puma.io)
* _[capistrano-delayed_job](https://github.com/leifcr/capistrano-delayed_job)_ for [Delayed Job](https://github.com/collectiveidea/delayed_job)

It is fairly easy to create new service. Fork/clone either capistrano-puma or capistrano-delayed_job and create a new service based on either.

All services should have their own repository, as it makes it easier when deploying to choose what services you need for the application you are deploying.

## Capistrano tasks

Tasks that work on your entire application and not just on a single service.

_Note: The tasks will not work unless you have installed any monit services_

### Monit

All these tasks do monit tasks for all services setup with monit.

```
cap monit:disable               # Disable monit services for application
cap monit:enable                # Enable monit services for application
cap monit:main_config           # Setup main monit config file (/etc/monit/monitrc)
cap monit:monitor               # Monitor the application
cap monit:purge                 # Purge/remove all monit configurations for the application
cap monit:reload                # Reload monit config (global)
cap monit:restart               # Restart monitoring the application
cap monit:setup                 # Setup monit folders and configuration
cap monit:start                 # Start monitoring the application permanent (Monit saves state)
cap monit:status                # Status monit (global)
cap monit:stop                  # Stop monitoring the application permanent (Monit saves state)
```

#### Setup in your deploy file

You can add this to deploy.rb or env.rb in order to automatically monitor/unmonitor tasks

It is important to unmonitor tasks while deploying as they can trigger stops/restarts to the app that monit thinks are "crashes"

```ruby
before "deploy:started",  "monit:unmonitor"
after  "deploy:finished", "monit:monitor"
```

If you want monit to automatically start/stop runit instead of triggering seperately

```ruby
before "monit:unmonitor", "monit:stop"
after  "monit:monitor",   "monit:start"
```

### Runit

All these tasks do runit tasks for all services setup with runit.

```
cap runit:disable               # Disable runit services for application
cap runit:enable                # Enable runit services for application
cap runit:once                  # Only start services once.
cap runit:purge                 # Purge/remove all runit configurations for the application
cap runit:setup                 # Setup runit for the application
cap runit:start                 # Start all runit services for current application
cap runit:stop                  # Stop all runit services for current application
```

#### Setup in your deploy file

You can add this to deploy.rb or env.rb in order to automatically start/stop tasks

```ruby
before "deploy", "runit:stop"
after  "deploy", "runit:start"
```

See each gem if you want to start/stop each service separate instead of together.

## Assumptions

There are some assumptions when using this with capistrano.
The following variables must be set

* _:application_ - The application name
* _:user_ - The username which is running the deployed application (usually deploy..)
* _:group_ - The groupname which is running the deployed application (usually deploy..)

## Contributing

* Fork the project
* Make a feature addition or bug fix
* Please test the feature or bug fix, or write tests for it
* Make a pull request

## Copyright

(c) 2013-2015 Leif Ringstad. See LICENSE.txt for details

