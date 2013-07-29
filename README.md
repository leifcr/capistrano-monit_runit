# Capistrano - Base helpers

This libary is a helper library for capistrano tasks that setup monit/runit for various services.

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

_Note: This is already done in monit\_base.rb, so no additional setup in deploy.rb or env.rb required_

```ruby
before "deploy", "monit:unmonitor"
after  "deploy", "monit:monitor"
```

If you want monit to automatically start/stop runit instead of triggering seperately

```ruby
before "monit:unmonitor", "monit:stop"
after  "monit:monitor", "monit:start"
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


## Helpers

Upload a configuration file:

```ruby
# Generate a config file by parsing an ERB template and uploading the file. Both paths should be absolute
Capistrano::BaseHelper::generate_and_upload_config(local_file, remote_file, use_sudo=false)
```

Run a rake task:
```ruby
# Execute a rake taske using bundle and the proper env.
Capistrano::BaseHelper::run_rake(task)
```

Ask the user a message to agree/disagree
```ruby
Capistrano::BaseHelper::ask(message)
```

See base_helper/base_helper.rb for further documentation.
And for runit info, base_helper/runit_base.rb for further documentation.

## Contributing

* Fork the project
* Make a feature addition or bug fix
* Please test the feature or bug fix, or write tests for it
* Make a pull request

## Copyright

(c) 2013 Leif Ringstad. See LICENSE.txt for details

