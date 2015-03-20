module Capistrano
  module Helpers
    module Runit
      # Any command sent to this function controls _all_ services related to the app
      def runit_app_services_control(command)
        return unless test("[ ! -h '#{runit_etc_service_app_symlink_name}' ]")
        execute :sudo, :sv, "#{command} #{runit_etc_service_app_symlink_name}"
      end

      # Begin - single service control functions

      # def start_service_once(service_name)
      #   control_service(service_name, "once")
      # end

      # def start_service(service_name)
      #   control_service(service_name, "start")
      # end

      # def stop_service(service_name)
      #   control_service(service_name, "stop")
      # end

      # def restart_service(service_name)
      #   control_service(service_name, "restart")
      # end

      def control_service(service_name, command, arguments = '', _ignore_error = false)
        return unless test "[ -h '#{runit_service_path(service_name)}/run' ]"
        execute :sv, "#{arguments} #{command} #{runit_service_path(service_name)}"
      end

      # Will not check if the service exists before trying to force it down
      def force_control_service(service_name, command, arguments, _ignore_error = false)
        execute :sv, "#{arguments} #{command} #{runit_service_path(service_name)}"
      end

      def disable_service(service_name)
        begin
          force_control_service(service_name, 'force-stop', '', true) # force-stop the service before disabling it
        rescue
        end
        within(runit_service_path(service_name)) do
          execute :rm, '-f ./run' if test "[ -h '#{runit_service_run_file(service_name)}' ]"
          execute :rm, '-f ./finish' if test "[ -h '#{runit_service_finish_file(service_name)}' ]"
        end
      end

      def enable_service(service_name)
        within(runit_service_path(service_name)) do
          execute :ln, "-sf #{runit_service_run_config_file(service_name)} ./run" if test "[ ! -h '#{runit_service_run_file(service_name)}' ]"
          execute :ln, "-sf #{runit_service_finish_config_file(service_name)} ./finish" if test "[ ! -h '#{runit_service_finish_file(service_name)}' ]"
        end
      end

      def purge_service(service_name)
        execute :rm, "-rf #{runit_service_path(service_name)}"
      end

      def runit_set_executable_files(service_name) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        if test("[ -f '#{runit_service_run_config_file(service_name)}' ]")
          execute :chmod, "775 #{runit_service_run_config_file(service_name)}"
        end
        if test("[ -f '#{runit_service_finish_config_file(service_name)}' ]")
          execute :chmod, "775 #{runit_service_finish_config_file (service_name)}"
        end

        if test("[ -f '#{runit_service_log_run_file(service_name)}' ]")
          execute :chmod, "775 #{runit_service_log_run_file(service_name)}"
        end

        if test("[ -d '#{runit_service_control_path(service_name)}' ]") # rubocop:disable Style/GuardClause
          execute :chmod, "775 -R #{runit_service_control_path(service_name)}"
          # execute :chmod, 'u+x -R runit_service_control_path(service_name)'
          # execute :chmod, 'g+x -R runit_service_control_path(service_name)'
        end
      end

      # End - single service control functions
    end
  end
end
