module Capistrano
  module DSL
    ##
    # Paths and filenames for runit
    #
    # Main app services are placed under
    # /etc/sv/username/appname_env
    #
    # They are symlinked for enabling / disabling the entire app like this:
    # /etc/service/username_appname_env --> /etc/sv/username/appname_env
    #
    # All services run/finish scripts e.g. puma/delayed job etc are located in
    # 'shared_folder'/runit/service_name/
    module RunitPaths
      # /etc/sv
      def runit_etc_sv_path
        File.join('/etc', 'sv')
      end

      def runit_user_base_path
        File.join(runit_etc_sv_path, fetch(:user))
      end

      def runit_base_path
        File.join(runit_etc_sv_path, user_app_env_folder)
      end

      def runit_base_log_path
        File.join(runit_base_path, 'log')
      end

      def runit_run_file
        File.join(runit_base_path, 'run')
      end

      def runit_finish_file
        File.join(runit_base_path, 'finish')
      end

      def runit_log_run_file
        File.join(runit_base_log_path, 'run')
      end

      # /var/log/service/ ++
      def runit_var_log_service_path
        File.join('/var', 'log', 'service', user_app_env_folder, 'runit')
      end

      # /etc/service
      def runit_etc_service_path
        File.join('/etc', 'service')
      end

      def runit_etc_service_app_symlink_name
        File.join('/etc', 'service', user_app_env_file_name)
      end

      # Paths and files in shared_folder
      def runit_service_path(service_name)
        File.join(fetch(:runit_dir), service_name)
      end

      def runit_service_log_path(service_name)
        File.join(runit_service_path(service_name), 'log')
      end

      def runit_service_control_path(service_name)
        File.join(runit_service_path(service_name), 'control')
      end

      def runit_service_control_file(service_name, control_letter)
        File.join(runit_service_control_path(service_name), control_letter)
      end

      def runit_service_log_run_file(service_name)
        File.join(runit_service_log_path(service_name), 'run')
      end

      def runit_service_run_file(service_name)
        File.join(runit_service_path(service_name), 'run')
      end

      def runit_service_finish_file(service_name)
        File.join(runit_service_path(service_name), 'finish')
      end

      def runit_service_run_config_file(service_name)
        File.join(runit_service_path(service_name), "#{service_name}_run")
      end

      def runit_service_finish_config_file(service_name)
        File.join(runit_service_path(service_name), "#{service_name}_finish")
      end

      def create_service_folders(service_name)
        if test "[ -d #{runit_service_path(service_name)} ]"
          execute :mkdir, "-p #{runit_service_path(service_name)}"
        end
        if test "[ -d #{runit_service_path(service_name)} ]"
          execute :mkdir, "-p #{runit_service_path(service_name)}"
        end
      end

      def service_pid(service_name)
        File.join(runit_service_path(service_name), 'supervise', 'pid')
      end
    end
  end
end
