# Capistrano - Monit and Runit helpers

This libary is a helper library for capistrano tasks that setup [runit](smarden.org/runit/) and [monit](http://mmonit.com/monit) for various services.

Note: This has been updated to support Capistrano >= 3.4. If you still use Capistrano 2.x, see the capistrano2 branch

## Versioning

Use 3.x for capistrano 3

For capistrano2, see the capistrano2 branch (will not be updated)

## Usage

You are unlikely to require this library without any of the libraries
depending on it.

But if you do require only Runit and Monit capistrano helpers, add this to your Gemfile in the development section.

```ruby
gem 'capistrano-runit_monit', require: false
```

In your Capfile:

```ruby
require 'capistrano/monit'
require 'capistrano/runit'
```

## Sudoing

You should setup sudoers to allow control over monit and runit from the deployment user in either Salt, puppet, chef or
other form for infrastructure setup

The cap tasks for creating a sudoers list has been deprecated, as it does not belong to deployment of an app

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
before 'deploy:updating', 'monit:unmonitor'
after 'deploy:finished', 'monit:monitor'
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
before "deploy:updating", "runit:stop"
after  "deploy:finished", "runit:start"
```

Or just before finishing the update:

```ruby
before "deploy:finished", "runit:stop"
after  "deploy:finished", "runit:start"
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
