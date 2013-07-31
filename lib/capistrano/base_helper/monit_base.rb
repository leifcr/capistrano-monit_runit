# Monit Base config
# Shared config for all apps that use monit
#
# Monit service config locations:
# Available services: shared_path/monit/available
# Enabled services: shared_path/monit/enabled
# Application "global" config: shared_path/monit/application.conf <-- in this: include shared_path/monit/enabled
# 
# For control of monit, sudo is required, as it always runs as root. (Unfortunately.)
#

Capistrano::Configuration.instance(true).load do
  _cset :monit_dir,            defer { File.join(shared_path, "monit") }
  _cset :monit_available_path, defer { File.join(monit_dir, "available") }
  _cset :monit_enabled_path,   defer { File.join(monit_dir, "enabled") }
  _cset :monit_etc_path,       File.join("/etc", "monit") 
  _cset :monit_etc_conf_d_path,  defer { File.join(monit_etc_path, "conf.d") }
  _cset :monit_application_group_name,  defer { "#{fetch(:user)}_#{fetch(:application)}_#{Capistrano::BaseHelper.environment}" }

  _cset :monit_mailserver,      "localhost"
  _cset :monit_mail_sender,     "monit@$HOST"
  _cset :monit_mail_reciever,   nil # if this is nil, alerts are disabled
  _cset :monit_use_httpd,       "true"
  _cset :monit_httpd_bind_address,  "localhost"
  _cset :monit_httpd_allow_address, "localhost"
  _cset :monit_httpd_signature,     "enable" # or enable
  _cset :monit_httpd_port, "2812"

  _cset :monit_daemon_time, "60"
  _cset :monit_start_delay, "60"

  _cset :monit_local_monitrc,     File.join(File.expand_path(File.join(File.dirname(__FILE__),"../../../templates", "monit")), "monitrc.erb")
  _cset :monit_local_application_conf, File.join(File.expand_path(File.join(File.dirname(__FILE__),"../../../templates", "monit")), "app_include.conf.erb")

  _cset :monit_remote_monitrc, File.join("/etc","monit","monitrc")
  _cset :monit_remote_application_conf, File.join(fetch(:monit_dir), "monit.conf")

  #after "deploy:update", "monit:enable"
  after "deploy:setup", "monit:setup"
  before "monit:setup",  "monit:main_config"

  after "monit:setup", "monit:enable"
  after "monit:enable", "monit:reload"

  # This should be done in the app, as the sequence of restarting services can be specific
  # must trigger monitor after deploy
  # after "deploy", "monit:monitor"
  # must trigger unmonitor before deploy
  # before "deploy", "monit:unmonitor"

  before "monit:disable", "monit:unmonitor"
  after "monit:disable", "monit:reload"
  
  before "monit:purge", "monit:unmonitor"

  namespace :monit do

    desc "Setup monit folders and configuration"
    task :setup, :roles => [:app, :db, :web] do
      # conf file that will include application specific configurations will be placed here:
      run "[ -d #{fetch(:monit_dir)} ] || mkdir -p #{fetch(:monit_dir)}"
      # dir to store each services monit configs
      run "[ -d #{fetch(:monit_available_path)} ] || mkdir -p #{fetch(:monit_available_path)}"
      # dir for all symlinked enabled applications
      run "[ -d #{fetch(:monit_enabled_path)} ] || mkdir -p #{fetch(:monit_enabled_path)}"

      # create include configuration (used when booting the system)

      Capistrano::BaseHelper::generate_and_upload_config(fetch(:monit_local_application_conf), fetch(:monit_remote_application_conf))
    end

    desc "Setup main monit config file (/etc/monit/monitrc)"
    task :main_config, :roles => [:app, :db, :web] do
      if Capistrano::CLI.ui.agree("Setup /etc/monit/monitrc ?")
         # create monitrc file
        Capistrano::BaseHelper::generate_and_upload_config(fetch(:monit_local_monitrc), fetch(:monit_remote_monitrc), true)

        commands = []
        commands << "#{sudo} chmod 700 /etc/monit/monitrc"
        commands << "#{sudo} chown root:root /etc/monit/monitrc"
        run commands.join(" && ")
        # restart monit, as main config is now updated
        run "#{sudo} service monit restart"
        puts "----------------------------------------"
        puts "Sleeping for #{fetch(:monit_start_delay).to_i + 10} seconds to wait for monit to be ready"
        puts "----------------------------------------"
        sleep (fetch(:monit_start_delay).to_i + 2)
      end
    end

    desc "Enable monit services for application"
    task :enable, :roles => [:app, :db, :web] do
      real_conf   = File.join(fetch(:monit_dir), "monit.conf")
      symlink   = File.join(fetch(:monit_etc_conf_d_path), "#{Capistrano::BaseHelper.user_app_env_underscore}.conf")
      # symlink to include file
      run("[ -h #{symlink} ] || #{sudo} ln -sf #{real_conf} #{symlink}")
    end
 
    desc "Disable monit services for application"
    task :disable, :roles => [:app, :db, :web] do
      symlink   = File.join(fetch(:monit_etc_conf_d_path), "#{Capistrano::BaseHelper.user_app_env_underscore}.conf")
      run("[ ! -h #{symlink} ] || #{sudo} rm -f #{symlink}")
    end

    desc "Purge/remove all monit configurations for the application"
    task :purge, :roles => [:app, :db, :web] do
      symlink   = File.join(fetch(:monit_etc_conf_d_path), "#{Capistrano::BaseHelper.user_app_env_underscore}.conf")
      run("[ ! -h #{symlink} ]   || #{sudo} rm -f #{symlink}")
      run("[ ! -d #{fetch(:monit_dir)} ] || #{sudo} rm -f #{fetch(:monit_dir)}")
    end

    desc "Monitor the application"
    task :monitor, :roles => [:app, :db, :web] do
      Capistrano::MonitBase::Application::command_monit_group(fetch(:monit_application_group_name), "monitor")
    end 

    desc "Unmonitor the application"
    task :unmonitor, :roles => [:app, :db, :web] do
      Capistrano::MonitBase::Application::command_monit_group(fetch(:monit_application_group_name), "unmonitor")
    end 

    desc "Stop monitoring the application permanent (Monit saves state)"
    task :stop, :roles => [:app, :db, :web] do
      Capistrano::MonitBase::Application::command_monit_group(fetch(:monit_application_group_name), "stop")
    end 

    desc "Start monitoring the application permanent (Monit saves state)"
    task :start, :roles => [:app, :db, :web] do
      Capistrano::MonitBase::Application::command_monit_group(fetch(:monit_application_group_name), "start")
    end

    desc "Restart monitoring the application"
    task :restart, :roles => [:app, :db, :web] do
      Capistrano::MonitBase::Application::command_monit_group(fetch(:monit_application_group_name), "restart")
    end

    desc "Reload monit config (global)"
    task :reload, :roles => [:app, :db, :web] do
      Capistrano::MonitBase::Application::command_monit("reload")
    end

    desc "Status monit (global)"
    task :status, :roles => [:app, :db, :web], :on_error => :continue do
      Capistrano::MonitBase::Application::command_monit("status")
    end

    desc "Summary monit (global)"
    task :summary, :roles => [:app, :db, :web], :on_error => :continue do
      Capistrano::MonitBase::Application::command_monit("summary")
    end

    desc "Validate monit (global)"
    task :validate, :roles => [:app, :db, :web], :on_error => :continue do
      Capistrano::MonitBase::Application::command_monit("validate")
    end

  end
end

module Capistrano
  module MonitBase
    module Application
      module_function

      ##
      # Control / Command a monit group
      # namescheme: user_application_environment "#{user}_#{application}_#{environment}"
      #
      def command_monit_group(application_group_name, command, arguments = "")
        Capistrano::MonitBase::Application.command_monit(command, "-g #{application_group_name} #{arguments}")
      end

      ##
      # Control / Command monit with given arguments
      def command_monit(command, arguments="")
        c = Capistrano::BaseHelper.get_capistrano_instance
        c.run("#{c.sudo} monit #{arguments} #{command}")
      end

    end

    module Service
      module_function

      ##
      # Command a single monit service
      #
      # The service name scheme is recommended to be 
      # "#{user}_#{application}_#{environment}_#{service}" 
      #
      def command_monit(command, service_name="", arguments="")
        c = Capistrano::BaseHelper.get_capistrano_instance
        service_name = "#{c.fetch(:user)}_#{c.fetch(:application)}_#{c.fetch(:environment)}_#{c.fetch(:service)}" if service_name == ""
        c.run("#{c.sudo} monit #{arguments} #{command} #{service_name}")
      end

      ##
      # The service name is the same as the conf file name for the service.
      # E.g. puma.conf
      #
      # This will symlink the service to enabled service, but not start or reload monit configuration 
      #
      def enable(service_conf_filename)
        c = Capistrano::BaseHelper.get_capistrano_instance
        c.run("[ -h #{File.join(c.fetch(:monit_enabled_path), service_conf_filename)} ] || ln -sf #{File.join(c.fetch(:monit_available_path), service_conf_filename)} #{File.join(c.fetch(:monit_enabled_path), service_conf_filename)}")
      end

      def disable(service_conf_filename)
        c = Capistrano::BaseHelper.get_capistrano_instance
        c.run("rm -f #{File.join(c.fetch(:monit_enabled_path), service_conf_filename)}")
      end
    end  
  end
end

