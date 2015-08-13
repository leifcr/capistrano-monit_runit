# Monit capistrano 3.x tasks
#
# Application config and tasks that apply to all services setup
# with monit for the application
#
# Recommendation:
# Let monit monitor any long-running processes to ensure they keep
# within the limits set by you.

require 'capistrano/dsl/base_paths'
require 'capistrano/dsl/monit_paths'
require 'capistrano/helpers/base'
require 'capistrano/helpers/monit'

include Capistrano::DSL::BasePaths
include Capistrano::DSL::MonitPaths
include Capistrano::Helpers::Base
include Capistrano::Helpers::Monit

namespace :load do
  task :defaults do
    set :monit_dir,            proc { shared_path.join('monit') }
    set :monit_available_path, proc { File.join(fetch(:monit_dir), 'available') }
    set :monit_enabled_path,   proc { File.join(fetch(:monit_dir), 'enabled') }
    set :monit_application_group_name,  proc { user_app_env_underscore }

    set :monit_mailserver,          'localhost'
    set :monit_mail_sender,         'monit@$HOST'
    set :monit_mail_reciever,       nil # if this is nil, alerts are disabled
    set :monit_use_httpd,           'true'
    set :monit_httpd_bind_address,  'localhost'
    set :monit_httpd_allow_address, 'localhost'
    set :monit_httpd_signature,     'enable' # or enable
    set :monit_httpd_port,          '2812'

    set :monit_daemon_time,         '30'
    set :monit_start_delay,         '30'

    set :monit_monitrc_template,           File.join(File.expand_path(File.join(File.dirname(__FILE__), '../../../templates', 'monit')), 'monitrc.erb')  # rubocop:disable Metrics/LineLength:
    set :monit_application_conf_template,  File.join(File.expand_path(File.join(File.dirname(__FILE__), '../../../templates', 'monit')), 'app_include.conf.erb')  # rubocop:disable Metrics/LineLength:

    set :monit_application_conf_file, proc { File.join(fetch(:monit_dir), 'monit.conf') }

    set :monit_event_dir, File.join('/var', 'run', 'monit')
  end
end

namespace :monit do
  desc 'Get the config needed to add to sudoers'
  task :sudoers do
    run_locally do
      puts '# -----------------------------------------------------------------------------------------'
      puts "# Sudo monit entries for #{fetch(:application)}"
      puts "#{fetch(:user)} ALL=NOPASSWD: /bin/chmod 0700 #{monit_monitrc_file}"
      puts "#{fetch(:user)} ALL=NOPASSWD: /bin/chmod 0775 #{monit_etc_path}"
      puts "#{fetch(:user)} ALL=NOPASSWD: /bin/chmod 0700 #{monit_etc_path}"
      puts "#{fetch(:user)} ALL=NOPASSWD: /bin/mkdir -p #{monit_etc_conf_d_path}"
      puts "#{fetch(:user)} ALL=NOPASSWD: /bin/chmod 6775 #{monit_etc_conf_d_path}"
      puts "#{fetch(:user)} ALL=NOPASSWD: /bin/chown #{fetch(:user)}\\:root #{monit_etc_path}"
      puts "#{fetch(:user)} ALL=NOPASSWD: /bin/chown #{fetch(:user)}\\:root #{monit_etc_conf_d_path}"
      puts "#{fetch(:user)} ALL=NOPASSWD: /bin/chown #{fetch(:user)}\\:root #{monit_monitrc_file}"
      puts "#{fetch(:user)} ALL=NOPASSWD: /bin/chown root\\:root #{monit_monitrc_file}"
      puts "#{fetch(:user)} ALL=NOPASSWD: /usr/bin/monit *"
      puts "#{fetch(:user)} ALL=NOPASSWD: /usr/sbin/service monit *"
      puts "#{fetch(:user)} ALL=NOPASSWD: /bin/mkdir -p #{fetch(:monit_event_dir)}"
      puts '# -----------------------------------------------------------------------------------------'
    end
    # info "#{fetch(:user)} ALL=NOPASSWD: /bin/chown deploy:root #{monit_monitrc_file}"
  end

  desc 'Setup monit for the application'
  task :setup do
    on roles(:app) do |host|
      info "MONIT: Setting up initial monit configuration on #{host}"
      if test "[ ! -d #{fetch(:monit_dir)} ]"
        execute :mkdir, "-p #{fetch(:monit_dir)}"
      end
      if test "[ ! -d #{fetch(:monit_available_path)} ]"
        execute :mkdir, "-p #{fetch(:monit_available_path)}"
      end
      if test "[ ! -d #{fetch(:monit_enabled_path)} ]"
        execute :mkdir, "-p #{fetch(:monit_enabled_path)}"
      end

      if test("[ ! -d #{monit_etc_conf_d_path} ]")
        execute :sudo, :mkdir, "-p #{monit_etc_conf_d_path}"
      end
      execute :sudo, :chmod, "6775 #{monit_etc_conf_d_path}"
      execute :sudo, :chown, "#{fetch(:user)}:root #{monit_etc_conf_d_path}"

      # Upload application global monit include file
      upload! template_to_s_io(fetch(:monit_application_conf_template)), fetch(:monit_application_conf_file)
    end
  end

  desc 'Setup main monit config file (/etc/monit/monitrc)'
  task :main_config do
    on roles(:app) do |host|
      set :createmonitrc, ask("Create #{monit_monitrc_file} [Y/n]", 'Y')
      if fetch(:createmonitrc) == 'Y'
        info "MONIT: Creating #{monit_monitrc_file} on #{host}"
        execute :sudo, :chown, "#{fetch(:user)}:root #{monit_etc_path}"
        execute :sudo, :chmod, "0775 #{monit_etc_path}"
        execute :sudo, :chown, "#{fetch(:user)}:root #{monit_monitrc_file}"
        if test("[ -e #{monit_monitrc_file} ]")
          execute :sudo, :rm, "-f #{monit_monitrc_file}"
        end

        upload! template_to_s_io(fetch(:monit_monitrc_template)), monit_monitrc_file
        execute :sudo, :chmod, "0700 #{monit_monitrc_file}"
        execute :sudo, :chown, "root:root #{monit_monitrc_file}"
        execute :sudo, :service, 'monit restart'
        execute :sudo, :mkdir, "-p #{fetch(:monit_event_dir)}"
        info "MONIT: Sleeping for #{fetch(:monit_start_delay).to_i} seconds to wait for monit to be ready"
        sleep(fetch(:monit_start_delay).to_i)
      end
    end
  end

  desc 'Enable monit services for application'
  task :enable do
    on roles(:app) do |host|
      if test("[ ! -h #{monit_etc_app_symlink} ]")
        info "MONIT: Enabling for #{fetch(:application)} on #{host}"
        execute :ln, "-sf #{fetch(:monit_application_conf_file)} #{monit_etc_app_symlink}"
      else
        info "MONIT: Already enabled for #{fetch(:application)} on #{host}"
      end
    end
  end

  desc 'Disable monit services for application'
  task :disable do
    on roles(:app) do |host|
      if test("[ -h #{monit_etc_app_symlink} ]")
        info "MONIT: Disabling for #{fetch(:application)} on #{host}"
        execute :rm, "-f #{monit_etc_app_symlink}"
      else
        info "MONIT: Already disabled for #{fetch(:application)} on #{host}"
      end
    end
  end

  desc 'Purge/remove all monit configurations for the application'
  task :purge do
    on roles(:app) do |host|
      info "MONIT: 'Purging config on #{host}"
      execute :rm, "-rf #{fetch(:monit_dir)}" if test("[ -d #{fetch(:monit_dir)} ]")
      execute :rm, "-f #{monit_etc_app_symlink}"
    end
  end

  desc 'Monitor the application'
  task :monitor do
    on roles(:app) do |host|
      info "MONIT: Application: Monitoring on #{host}"
      command_monit_group('monitor')
    end
  end

  desc 'Unmonitor the application'
  task :unmonitor do
    on roles(:app) do |host|
      info "MONIT: Application: Unmonitoring on #{host}"
      command_monit_group('unmonitor')
    end
  end

  desc 'Stop monitoring the application permanent (Monit saves state)'
  task :stop do
    on roles(:app) do |host|
      info "MONIT: Application: Stopping on #{host}"
      command_monit_group('stop')
    end
  end

  desc 'Start monitoring the application permanent (Monit saves state)'
  task :start do
    on roles(:app) do |host|
      info "MONIT: Application: Starting on #{host}"
      command_monit_group('start')
    end
  end

  desc 'Restart monitoring the application'
  task :restart do
    on roles(:app) do |host|
      info "MONIT: Application: Restarting on #{host}"
      command_monit_group('restart')
    end
  end

  desc 'Reload monit config (global)'
  task :reload do
    on roles(:app) do |host|
      info "MONIT: Global: Reloading on #{host}"
      command_monit('reload')
    end
  end

  desc 'Status monit (global)'
  task :status do
    on roles(:app) do |host|
      info "MONIT: Global: Status on #{host}"
      command_monit('status')
    end
  end

  desc 'Summary monit (global)'
  task :summary do
    on roles(:app) do |host|
      info "MONIT: Global: Summary for #{host}"
      command_monit('summary')
    end
  end

  desc 'Validate monit (global)'
  task :validate do
    on roles(:app) do |host|
      info "MONIT: Global: Validating config on #{host}"
      command_monit('validate')
    end
  end
end

# after 'deploy:update', 'monit:enable'
# after 'deploy:setup', 'monit:setup'
before 'monit:setup',  'monit:main_config'
# after 'monit:setup', 'monit:enable'
after 'monit:enable', 'monit:reload'

# This should be done in the app, as the sequence of restarting services can be specific
# must trigger monitor after deploy
# after 'deploy', 'monit:monitor'
# must trigger unmonitor before deploy
# before 'deploy', 'monit:unmonitor'

before 'monit:disable', 'monit:unmonitor'
after 'monit:disable', 'monit:reload'

before 'monit:purge', 'monit:unmonitor'

after 'sudoers', 'monit:sudoers'
