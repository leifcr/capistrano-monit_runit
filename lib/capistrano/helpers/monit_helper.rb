module Capistrano
  ##
  # Helper functions for monit
  #
  module MonitHelper
    ##
    # Control / Command monit with given arguments
    def command_monit(command, arguments = '')
      execute :sudo, :monit, "#{arguments} #{command}"
    end

    ##
    # Control / Command a monit group
    # namescheme: user_application_environment "#{user}_#{application}_#{environment}"
    #
    def command_monit_group(application_group_name, command, arguments = '')
      command_monit(command, "-g #{application_group_name} #{arguments}")
    end

    ##
    # Command a single monit service
    #
    # The service name scheme is recommended to be
    # "#{user}_#{application}_#{environment}_#{service}"
    #
    def command_monit_service(command, service_name, arguments = '')
      execute :sudo, :monit, "#{arguments} #{command} #{service_name}"
    end

    ##
    # The service name is the same as the conf file name for the service.
    # E.g. puma.conf
    #
    # This will symlink the service to enabled service, but not start or reload monit configuration
    #
    def enable_service(service_conf_filename)
      return unless test("[ -h #{File.join(c.fetch(:monit_enabled_path), service_conf_filename)} ]")
      execute :ln, "-sf #{File.join(c.fetch(:monit_available_path), service_conf_filename)} #{File.join(c.fetch(:monit_enabled_path), service_conf_filename)}" # rubocop:disable Metrics/LineLength:
    end

    def disable_service(service_conf_filename)
      execute :rm, "-f #{File.join(c.fetch(:monit_enabled_path), service_conf_filename)}"
    end
  end
end
