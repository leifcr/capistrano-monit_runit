# Runit capistrano 3.x tasks
#
# Application config and tasks that apply to all services setup
# with runit for the application
#
# Recommendation:
# Everything that should run as either a service or deamon,
# can and should use runit

require 'capistrano/dsl/base_paths'
require 'capistrano/dsl/runit_paths'
require 'capistrano/helpers/base'
require 'capistrano/helpers/runit'

include Capistrano::DSL::BasePaths
include Capistrano::DSL::RunitPaths
include Capistrano::Helpers::Base
include Capistrano::Helpers::Runit

namespace :load do
  task :defaults do
    set :runit_dir,               proc { shared_path.join('runit') }
    set :runit_run_template,      File.join(File.expand_path(File.join(File.dirname(__FILE__), '../../../templates')), 'runit', 'run.erb') # rubocop:disable Metrics/LineLength:
    set :runit_finish_template,   File.join(File.expand_path(File.join(File.dirname(__FILE__), '../../../templates')), 'runit', 'finish.erb') # rubocop:disable Metrics/LineLength:
    set :runit_log_run_template,  File.join(File.expand_path(File.join(File.dirname(__FILE__), '../../../templates')), 'runit', 'log_run.erb') # rubocop:disable Metrics/LineLength:
    set :runit_log_user,          'syslog'
    set :runit_log_group,         'syslog'
    set :runit_restart_interval,  10
    set :runit_restart_count,     7
    set :runit_autorestart_clear_interval, 90
  end
end

namespace :runit do
  desc 'Get the config needed to add to sudoers for all commands'
  task :sudoers do
    run_locally do
      puts '# -----------------------------------------------------------------------------------------'
      puts "# Sudo runit entries for #{fetch(:application)}"
      puts "#{fetch(:user)} ALL=NOPASSWD: /bin/mkdir -p #{runit_user_base_path}"
      puts "#{fetch(:user)} ALL=NOPASSWD: /bin/chown #{fetch(:user)}\\:root #{runit_user_base_path}"
      puts "#{fetch(:user)} ALL=NOPASSWD: /bin/chmod 6775 #{runit_user_base_path}"
      puts "#{fetch(:user)} ALL=NOPASSWD: /bin/mkdir -p #{runit_etc_service_path}"
      puts "#{fetch(:user)} ALL=NOPASSWD: /bin/chown #{fetch(:user)}\\:root #{runit_etc_service_path}"
      puts "#{fetch(:user)} ALL=NOPASSWD: /bin/chmod 6775 #{runit_etc_service_path}"
      puts "#{fetch(:user)} ALL=NOPASSWD: /bin/mkdir -p #{runit_var_log_service_path}"
      puts "#{fetch(:user)} ALL=NOPASSWD: /bin/chown #{fetch(:user)}\\:root #{runit_var_log_service_path}"
      puts "#{fetch(:user)} ALL=NOPASSWD: /bin/chown -R #{fetch(:user)}\\:#{fetch(:runit_log_group)} #{runit_var_log_service_path}" # rubocop:disable Metrics/LineLength:
      puts "#{fetch(:user)} ALL=NOPASSWD: /bin/chmod 6775 #{runit_var_log_service_path}"
      puts "#{fetch(:user)} ALL=NOPASSWD: /usr/bin/sv *"
      puts '# -----------------------------------------------------------------------------------------'
    end
    # info "#{fetch(:user)} ALL=NOPASSWD: /bin/chown deploy:root #{monit_monitrc_file}"
  end

  desc 'Setup runit for the application'
  task :setup do
    on roles(:app) do |host|
      info "RUNIT: Setting up initial runit configuration on #{host}"
      if test "[ ! -f #{fetch(:runit_dir)}/.env/HOME ]"
        if test "[ ! -d #{fetch(:runit_dir)}/.env ]"
          execute :mkdir, "-p '#{fetch(:runit_dir)}/.env'"
        end
        upload! StringIO.new('$HOME'), "#{File.join(fetch(:runit_dir), '.env', 'HOME')}"
      end
    end
  end

  namespace :setup do
    # '[INTERNAL] create /etc/sv folders and upload base templates needed'
    task :runit_create_app_services do
      on roles(:app) do |host|
        # set :pw, ask("Sudo password", '')
        # execute :echo, "#{fetch(:pw)} | sudo -S ls /"
        execute :sudo, :mkdir, "-p '#{runit_user_base_path}'" if test("[ ! -d '#{runit_user_base_path}' ]")
        execute :sudo, :chown, "#{fetch(:user)}:root '#{runit_user_base_path}'"
        execute :sudo, :chmod, "6775 '#{runit_user_base_path}'"

        execute :sudo, :mkdir, "-p '#{runit_etc_service_path}'" if test("[ ! -d '#{runit_etc_service_path}' ]")
        execute :sudo, :chown, "#{fetch(:user)}:root '#{runit_etc_service_path}'"
        execute :sudo, :chmod, "6775 '#{runit_etc_service_path}'"
        within("#{runit_user_base_path}") do
          execute :mkdir, "-p #{app_env_folder}"
        end

        upload! template_to_s_io(fetch(:runit_run_template)), runit_run_file
        upload! template_to_s_io(fetch(:runit_finish_template)), runit_finish_file

        # Should now work without sudo... ?
        execute :chmod, "0775 '#{runit_run_file}'"
        execute :chmod, "0775 '#{runit_finish_file}'"
        info "RUNIT: Created inital runit services in #{runit_base_path} for #{fetch(:application)} on #{host}"
      end
    end

    # [Internal] create log service for app
    task :runit_create_app_log_services do
      on roles(:app) do |host|
        within("#{runit_base_path}") do
          execute :mkdir, '-p log'
        end
        upload! template_to_s_io(fetch(:runit_log_run_template)), runit_log_run_file
        if test("[ ! -d #{runit_var_log_service_path} ]")
          execute :sudo, :mkdir, "-p '#{runit_var_log_service_path}'"
          execute :sudo, :chmod, "6775 '#{runit_var_log_service_path}'"
          execute :sudo, :chown, "-R #{fetch(:user)}:#{fetch(:runit_log_group)} '#{runit_var_log_service_path}'" # rubocop:disable Metrics/LineLength:
        end
        execute :mkdir, "-p #{runit_var_log_service_runit_path}" if test("[ ! -d #{runit_var_log_service_runit_path} ]")
        execute :chmod, "775 '#{runit_log_run_file}'"

        info "RUNIT: Created inital runit log services in #{runit_base_log_path} for #{fetch(:application)} on #{host}"
      end
    end
    # '[INTERNAL] create /etc/sv folders and upload base templates needed'
    task :runit_ensure_shared_sockets_and_pids_folders do
      on roles(:app) do |host|
        execute :mkdir, fetch(:pids_path) if test("[ ! -d #{fetch(:pids_path)} ]")
        execute :mkdir, fetch(:sockets_path) if test("[ ! -d #{fetch(:sockets_path)} ]")
      end
    end
  end

  desc 'Disable runit services for application'
  task :disable do
    on roles(:app) do |host|
      if test "[ -h #{runit_etc_service_app_symlink_name} ]"
        execute :rm, "-rf '#{runit_etc_service_app_symlink_name}'"
        info "RUNIT disabling on '#{host}'"
      else
        info "RUNIT already disabled on '#{host}'"
      end
    end
  end

  desc 'Enable runit services for application'
  task :enable do
    on roles(:app) do |host|
      if test "[ ! -h #{runit_etc_service_app_symlink_name} ]"
        execute :ln, "-sf '#{runit_base_path}' '#{runit_etc_service_app_symlink_name}'"
        info "RUNIT enabling on '#{host}'"
      else
        info "RUNIT already enabled on '#{host}'"
      end
    end
  end

  desc 'Purge/remove all runit configurations for the application'
  task :purge do
    on roles(:app) do |host|
      execute :rm, "-rf #{runit_etc_service_app_symlink_name}"
      execute :rm, "-rf #{runit_base_path}"
      info "RUNIT purging config on '#{host}'"
    end
  end

  %w(stop start once restart).each do |single_cmd|
    desc "#{single_cmd} runit services for application"
    task single_cmd.to_sym do
      on roles(:app) do |host|
        info "RUNIT: #{single_cmd} on #{host}"
        runit_app_services_control(single_cmd)
      end
    end
  end
end

before 'runit:purge',     'runit:stop'

after 'deploy:updated',   'runit:enable'
# after 'deploy:setup',     'runit:setup'
after 'runit:setup',      'runit:setup:runit_create_app_services'
after 'runit:setup:runit_create_app_services', 'runit:setup:runit_create_app_log_services'
after 'runit:setup:runit_create_app_services', 'runit:setup:runit_ensure_shared_sockets_and_pids_folders'
after 'sudoers', 'runit:sudoers'
