require 'base_helper'
Capistrano::Configuration.instance(true).load do
  _cset :runit_dir, defer { "#{shared_path}/runit" }
  _cset :runit_local_run,     File.join(File.expand_path(File.join(File.dirname(__FILE__),"../templates")), "runit",  "run.erb")
  _cset :runit_local_finish,  File.join(File.expand_path(File.join(File.dirname(__FILE__),"../templates")), "runit",  "finish.erb")
  _cset :runit_local_log_run, File.join(File.expand_path(File.join(File.dirname(__FILE__),"../templates")), "runit",  "log_run.erb")
  _cset :runit_remote_run,     defer {File.join("/etc", "sv", Capistrano::BaseHelper.user_app_env_path, "run")}
  _cset :runit_remote_finish,  defer {File.join("/etc", "sv", Capistrano::BaseHelper.user_app_env_path, "finish")}
  _cset :runit_remote_log_run, defer {File.join("/etc", "sv", Capistrano::BaseHelper.user_app_env_path, "log", "run")}
  _cset :runit_log_user, "syslog"
  _cset :runit_log_group, "syslog"

  after "deploy:update", "runit:enable"
  after "deploy:setup", "runit:setup"

  namespace :runit do
    desc "Setup runit for the application"
    task :setup, :roles => [:app, :db, :web] do
      run "[ -d #{fetch(:runit_dir)}/.env ] || mkdir -p #{fetch(:runit_dir)}/.env"
      run "echo $HOME > #{fetch(:runit_dir)}/.env/HOME"
      # setup to run as user
      Capistrano::RunitBase.app_services_create
    end

    desc "Disable runit services for application"
    task :disable, :roles => [:app, :db, :web] do
      Capistrano::BaseHelper.get_capistrano_instance.run("sudo sv force-stop #{user}_#{application}; true")
      Capistrano::RunitBase.app_services_disable(fetch(:application), fetch(:user))
    end

    desc "Enable runit services for application"
    task :enable, :roles => [:app, :db, :web] do
      Capistrano::RunitBase.app_services_enable(fetch(:application), fetch(:user))
    end

    desc "Purge/remove all runit configurations for the application"
    task :purge, :roles => [:app, :db, :web] do
      Capistrano::BaseHelper.get_capistrano_instance.run("sudo sv force-stop #{user}_#{application}; true")
      Capistrano::RunitBase.app_services_purge(fetch(:application), fetch(:user))
    end

    desc "Stop all runit services for current application"
    task :stop, :roles => [:app, :db, :web] do
      Capistrano::RunitBase.app_services_stop(fetch(:application), fetch(:user))
    end

    desc "Start all runit services for current application"
    task :start, :roles => [:app, :db, :web] do
      Capistrano::RunitBase.app_services_start(fetch(:application), fetch(:user))
    end

    desc "Only start services once. Will not restart if they fail."
    task :once, :roles => [:app, :db, :web] do
      Capistrano::RunitBase.app_services_once(fetch(:application), fetch(:user))
    end

  end
end

module Capistrano
  module RunitBase
    module_function

    def service_path(service_name)
      "#{Capistrano::BaseHelper.get_capistrano_instance.fetch(:runit_dir)}/#{service_name}"
    end

    def create_service_dir(service_name)
      Capistrano::BaseHelper.get_capistrano_instance.run("[ -d #{service_path(service_name)} ] || mkdir -p #{service_path(service_name)}")
    end

    def service_pid(service_name)
      File.join(service_path(service_name), "supervise", "pid")
    end

    # BEGIN - ALL services functions (functions that affects all services for the app)

    def app_services_create_log_service
      c = Capistrano::BaseHelper.get_capistrano_instance
      commands = []
      commands << "sudo mkdir -p #{File.join("/etc", "sv", Capistrano::BaseHelper.user_app_env_path, "log")}"
      commands << "sudo chown #{c.fetch(:user)}:root #{File.join("/etc", "sv", Capistrano::BaseHelper.user_app_env_path, "log")}"
      commands << "sudo mkdir -p '#{File.join("/var", "log", "service", Capistrano::BaseHelper.user_app_env_path, "runit")}'"
      commands << "sudo chown -R #{c.fetch(:runit_log_user)}:#{c.fetch(:runit_log_group)} '#{File.join("/var", "log", "service", Capistrano::BaseHelper.user_app_env_path, "runit")}'"

      c.run(commands.join(" && "))
      Capistrano::BaseHelper.generate_and_upload_config( Capistrano::BaseHelper::get_capistrano_instance.fetch(:runit_local_log_run), Capistrano::BaseHelper::get_capistrano_instance.fetch(:runit_remote_log_run), true )
      commands = []
      commands << "sudo chmod u+x '#{File.join("/etc", "sv", Capistrano::BaseHelper.user_app_env_path, "log", "run")}'"
      commands << "sudo chmod g+x '#{File.join("/etc", "sv", Capistrano::BaseHelper.user_app_env_path, "log", "run")}'"
      commands << "sudo chown #{c.fetch(:user)}:root '#{File.join("/etc", "sv", Capistrano::BaseHelper.user_app_env_path, "log", "run")}'"
      c.run(commands.join(" && ")) 
    end

    ##
    # application name should be "app-environment" or similar in case you deploy staging/production to same host
    def app_services_create
      # SEE http://off-the-stack.moorman.nu/posts/5-user-services-with-runit/ for info on scripts
      c = Capistrano::BaseHelper.get_capistrano_instance
      c.run("sudo mkdir -p '#{File.join("/etc", "sv", Capistrano::BaseHelper.user_app_env_path)}'")
      
      commands = []
      commands << "sudo chown #{c.fetch(:user)}:root /etc/sv/#{c.fetch(:user)}"
      commands << "sudo chown #{c.fetch(:user)}:root /etc/sv/#{Capistrano::BaseHelper.user_app_env_path}"
      c.run(commands.join(" && "))
      Capistrano::BaseHelper.generate_and_upload_config( Capistrano::BaseHelper::get_capistrano_instance.fetch(:runit_local_run), Capistrano::BaseHelper::get_capistrano_instance.fetch(:runit_remote_run), true )
      Capistrano::BaseHelper.generate_and_upload_config( Capistrano::BaseHelper::get_capistrano_instance.fetch(:runit_local_finish), Capistrano::BaseHelper::get_capistrano_instance.fetch(:runit_remote_finish), true )

      commands = []
      commands << "sudo chmod u+x '#{File.join("/etc", "sv", Capistrano::BaseHelper.user_app_env_path, "run")}'"
      commands << "sudo chmod u+x '#{File.join("/etc", "sv", Capistrano::BaseHelper.user_app_env_path, "finish")}'"
      commands << "sudo chmod g+x '#{File.join("/etc", "sv", Capistrano::BaseHelper.user_app_env_path, "run")}'"
      commands << "sudo chmod g+x '#{File.join("/etc", "sv", Capistrano::BaseHelper.user_app_env_path, "finish")}'"
      commands << "sudo chown #{c.fetch(:user)}:root '#{File.join("/etc", "sv", Capistrano::BaseHelper.user_app_env_path, "run")}'"
      commands << "sudo chown #{c.fetch(:user)}:root '#{File.join("/etc", "sv", Capistrano::BaseHelper.user_app_env_path, "finish")}'"
      c.run(commands.join(" && "))

      Capistrano::RunitBase.app_services_create_log_service
    end

    def app_services_enable(application, user)
      Capistrano::BaseHelper.get_capistrano_instance.run("[ -h /etc/service/#{user}_#{application}_#{Capistrano::BaseHelper.environment} ] || sudo ln -sf /etc/sv/#{Capistrano::BaseHelper.user_app_env_path} /etc/service/#{user}_#{application}_#{Capistrano::BaseHelper.environment}")
    end

    def app_services_disable(application, user)
      Capistrano::BaseHelper.get_capistrano_instance.run("[ ! -h /etc/service/#{user}_#{application}_#{Capistrano::BaseHelper.environment} ] || sudo rm -f /etc/service/#{user}_#{application}_#{Capistrano::BaseHelper.environment}")
    end

    def app_services_purge(application, user)
      # this should stop ALL services running for the given application
      # true is appended to ignore any errors failing to stop the services
      commands = []
      commands << "sudo rm -f /etc/service/#{user}_#{application}_#{Capistrano::BaseHelper.environment}"
      commands << "sudo rm -rf /etc/sv/#{Capistrano::BaseHelper.user_app_env_path}"
      Capistrano::BaseHelper.get_capistrano_instance.run(commands.join(" && "))
    end

    def app_services_stop(application, user, ignore_error = false)
      app_services_control(application, user, "stop", ignore_error)
    end

    def app_services_start(application, user, ignore_error = false)
      app_services_control(application, user, "start", ignore_error)
    end

    def app_services_once(application, user, ignore_error = false)
      app_services_control(application, user, "once", ignore_error)
    end

    def app_services_control(application, user, command, ignore_error = false)
      Capistrano::BaseHelper.get_capistrano_instance.run("[ ! -h /etc/service/#{user}_#{application} ] || sudo sv #{command} #{user}_#{application}; #{"true" if ignore_error != false}")
    end

    # END - ALL services functions (functions that affects all services for the app)


    # BEGIN - Single service functions (functions that affects a single given service)

    def start_service_once(service_name)
      control_service(service_name, "once")
    end

    def start_service(service_name)
      control_service(service_name, "start")
    end

    def stop_service(service_name)
      control_service(service_name, "stop")
    end

    def restart_service(service_name)
      control_service(service_name, "restart")
    end

    def control_service(service_name, service_control_function, ignore_error = false, arguments = "")
      Capistrano::BaseHelper.get_capistrano_instance.run("[ ! -h #{service_path(service_name)}/run ] || sv #{arguments} #{service_control_function} #{service_path(service_name)}")  
    end

    # Will not check if the service exists before trying to force it down
    def force_control_service(service_name, service_control_function, ignore_error = false)
      Capistrano::BaseHelper.get_capistrano_instance.run("sv #{service_control_function} #{service_path(service_name)}; #{"true" if ignore_error != false}")  
    end

    def disable_service(service_name)
      force_control_service(service_name, "force-stop", true) # force-stop the service before disabling it
      Capistrano::BaseHelper.get_capistrano_instance.run("[ ! -h #{service_path(service_name)}/run ] || rm -f #{service_path(service_name)}/run && rm -f #{service_path(service_name)}/finish")
    end

    def enable_service(service_name, symlink_finish = nil)
      Capistrano::BaseHelper.get_capistrano_instance.run("cd #{service_path(service_name)} && [ -h ./run ] || ln -sf #{remote_run_config_path(service_name)} ./run")
      Capistrano::BaseHelper.get_capistrano_instance.run("cd #{service_path(service_name)} && [ -h ./finish ] || ln -sf #{remote_finish_config_path(service_name)} ./finish") unless symlink_finish.nil?
    end

    def purge_service(service_name)
      Capistrano::BaseHelper.get_capistrano_instance.run("rm -rf #{service_path(service_name)}")
    end

    def remote_run_config_path(service_name)
      File.join(service_path(service_name), "#{service_name}_run")
    end

    def remote_finish_config_path(service_name)
      File.join(service_path(service_name), "#{service_name}_finish")
    end

    def remote_control_path(service_name, control_letter)
      File.join(remote_control_path_root(service_name), control_letter)
    end

    def remote_control_path_root(service_name)
      File.join(service_path(service_name), "control")
    end

    def remote_service_log_run_path(service_name)
      File.join(service_path(service_name), "log", "run")
    end

    def make_service_scripts_executeable(service_name)
      commands = []
      if Capistrano::BaseHelper::remote_file_exists?(Capistrano::RunitBase.remote_run_config_path(service_name))
        commands << "chmod u+x #{Capistrano::RunitBase.remote_run_config_path(service_name)}"
        commands << "chmod g+x #{Capistrano::RunitBase.remote_run_config_path(service_name)}"
      end
      if Capistrano::BaseHelper::remote_file_exists?(Capistrano::RunitBase.remote_service_log_run_path(service_name))
        commands << "chmod u+x #{Capistrano::RunitBase.remote_service_log_run_path(service_name)}"
        commands << "chmod g+x #{Capistrano::RunitBase.remote_service_log_run_path(service_name)}"
      end
      if Capistrano::BaseHelper::remote_file_exists?(Capistrano::RunitBase.remote_control_path_root(service_name))
        commands << "chmod u+x -R #{Capistrano::RunitBase.remote_control_path_root(service_name)}"
        commands << "chmod g+x -R #{Capistrano::RunitBase.remote_control_path_root(service_name)}"
      end
      Capistrano::BaseHelper.get_capistrano_instance.run commands.join(" ; ")
    end

    # note that the user running the runit service MUST be a member of the group or the same as the log user
    # If not, the log service will not work
    def create_and_permissions_on_path(log_path, user = nil, group = nil)
      user  = Capistrano::BaseHelper.get_capistrano_instance.fetch(:user) if user.nil?
      group = "syslog" if group.nil?
      # will use sudo
      commands = []
      commands << "sudo mkdir -p #{log_path}"
      commands << "sudo chown -R #{user}:#{group} #{log_path}"
      commands << "sudo chmod u+w #{log_path}"
      commands << "sudo chmod g+w #{log_path}"
      Capistrano::BaseHelper.get_capistrano_instance.run commands.join(" && ")
    end

    # END - Single service functions (functions that affects a single given service)
  end
end
