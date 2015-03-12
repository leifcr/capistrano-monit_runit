# Runit capistrano 3.x tasks
#
# Application config and tasks that apply to all services setup with runit for the application
#
# Recommendation: Everything that should run as either a service or deamon, use runit!

namespace :load do
  task :defaults do
    set :runit_dir,               Proc.new { shared_path.join("runit") }
    set :runit_run_template,      File.join(File.expand_path(File.join(File.dirname(__FILE__),"../../../templates")), "runit",  "run.erb")
    set :runit_finish_template,   File.join(File.expand_path(File.join(File.dirname(__FILE__),"../../../templates")), "runit",  "finish.erb")
    set :runit_log_run_template,  File.join(File.expand_path(File.join(File.dirname(__FILE__),"../../../templates")), "runit",  "log_run.erb")
    set :runit_log_user,          "syslog"
    set :runit_log_group,         "syslog"
    set :runit_restart_interval,  10
    set :runit_restart_count,     7
    set :runit_autorestart_clear_interval, 90
  end
end

namespace :runit do
  desc "Setup runit for the application"
  task :setup do
    on roles(:app) do |host|
      if test "[ -d #{fetch(:runit_dir)}/.env ]"
        execute :mkdir, "-p '#{fetch(:runit_dir)}/.env'"
      end
      execute :echo, "$HOME > '#{File.join(fetch(:runit_dir), 'env', 'HOME')}'"
      # create app services (files, folders etc)
    end
  end

  namespace :setup do
    # "[INTERNAL] create /etc/sv folders and upload base templates needed"
    task :runit_create_app_services do
      on roles(:app) do |host|
        execute :sudo, :mkdir "-p '#{runit_base_path}'"
        execute :sudo, :chown "#{c.fetch(:user)}:root '#{runit_user_base_path}'"
        execute :sudo, :chown "#{c.fetch(:user)}:root '#{runit_base_path}'"

        upload! template_to_s(fetch(:runit_run_template)), runit_run_file
        upload! template_to_s(fetch(:runit_finish_template)), runit_finish_file

        execute :sudo, :chmod "u+x '#{runit_run_file}'"
        execute :sudo, :chmod "u+x '#{runit_finish_file)}'"
        execute :sudo, :chmod "g+x '#{runit_run_file}'"
        execute :sudo, :chmod "g+x '#{runit_finish_file}'"
        execute :sudo, :chown "#{c.fetch(:user)}:root '#{runit_run_file}'"
        execute :sudo, :chown "#{c.fetch(:user)}:root '#{runit_finish_file}'"
        info "RUNIT: Created inital runit services in #{runit_base_path} for #{fetch(:application)}"
      end
    end

    # [Internal] create log service for app
    task :runit_create_app_log_services do
      on roles(:app) do |host|
        execute :sudo, :mkdir "-p #{runit_base_log_path}"
        execute :sudo, :chown "#{fetch(:user)}:root 'runit_base_log_path'"
        execute :sudo, :mkdir "-p '#{runit_var_log_service_path}'"
        execute :sudo, :chown "-R #{fetch(:runit_log_user)}:#{c.fetch(:runit_log_group)} '#{runit_var_log_service_path}'"

        upload! template_to_s(fetch(:runit_log_run_template)), runit_log_run_file

        execute :sudo, :chmod "u+x '#{runit_log_run_file)}'"
        execute :sudo, :chmod "g+x '#{runit_log_run_file)}'"
        execute :sudo, :chown "#{fetch(:user)}:root '#{runit_log_run_file)}'"

        info "RUNIT: Created inital runit log services in #{runit_base_path} for #{fetch(:application)}"
      end
    end
  end

  desc "Disable runit services for application"
  task :disable do
    on roles(:app) do |host|
      if test "[ ! -h #{runit_etc_service_app_symlink_name} ]"
        execute :sudo, :rm, "-rf '#{runit_etc_service_app_symlink_name}'")
      end
    end
  end

  desc "Enable runit services for application"
  task :enable do
    on roles(:app) do |host|
      if test "[ -h #{runit_etc_service_app_symlink_name} ]"
        execute :sudo, :ln, "-sf '#{runit_base_path}' '#{runit_etc_service_app_symlink_name}'")
      end
    end
  end

  desc "Purge/remove all runit configurations for the application"
  task :purge do
    on roles(:app) do |host|
      execute :sudo, :rm "-rf #{runit_base_path}"
      execute :sudo, :rm "-rf #{runit_etc_service_app_symlink_name}"
    end
  end

  desc "Stop all runit services for current application"
  task :stop do
    runit_app_services_control('stop')
  end

  desc "Start all runit services for current application"
  task :start do
    runit_app_services_control('start')
  end

  desc "Only start services once. Will not restart if they fail."
  task :once do
    runit_app_services_control('once')
  end
end

after "deploy:updated",   "runit:enable"
after "deploy:setup",     "runit:setup"
after "runit:setup",      "runit:setup:runit_create_app_services"
after "runit:setup:runit_create_app_services", "runit:setup:runit_create_app_log_services"
before "runit:purge",     "runit:stop"
