module Capistrano
  module Helpers
    ##
    # Helper functions for both runit and monit
    module Base
      def user_app_env_underscore
        "#{fetch(:user)}_#{fetch(:application)}_#{environment}"
      end

      def user_app_env_underscore_short
        "#{fetch(:user)[0...1]}_#{environment[0...1]}_#{fetch(:application)}"
      end

      def user_app_env_underscore_short_char_safe
        user_app_env_underscore_short.gsub!('-', '_')
      end

      ##
      # Automatically sets the environment based on presence of
      # :stage (multistage)
      # :rails_env
      # RAILS_ENV variable;
      #
      # Defaults to "production" if not found
      #
      def environment # rubocop:disable Metrics/MethodLength
        if exists?(:rails_env)
          fetch(:rails_env)
        elsif exists?(:rack_env)
          fetch(:rack_env)
        elsif exists?(:stage)
          fetch(:stage)
        else
          info '---------------------------------------------------------------'
          info '- Stage, rack or rails environment isn\'t set in               -'
          info '- :stage, :rails_env or :rack_env, defaulting to \'production\' -'
          info '---------------------------------------------------------------'
          'production'
        end
      end

      def template_to_s(template_file)
        fail "Cannot find templte #{template_file}" unless File.exist?(template_file)
        ERB.new(File.read(config_file)).result(binding)
      end

      ##
      # Execute a rake taske using the proper env.
      # run_rake db:migrate
      #
      def run_rake(task)
        within(current_path) do
          with rails_env: fetch(:rails_env) do
            execute :rake, "#{task}"
          end
        end
      end
    end
  end
end
