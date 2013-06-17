# Capistrano - Base helpers

This libary is used by capistrano-puma and capistrano-delayed-job

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

