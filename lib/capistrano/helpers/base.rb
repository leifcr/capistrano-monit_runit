require 'active_support'
require 'active_support/core_ext/string/filters'
module Capistrano
  module Helpers
    ##
    # Helper functions for both runit and monit
    module Base
      def user_app_env_underscore
        "#{fetch(:user)}_#{fetch(:application)}_#{environment}".squish.downcase.gsub(/[\s|-]/, '_')
      end

      def user_app_env_underscore_short
        "#{fetch(:user)[0...1]}_#{environment[0...1]}_#{fetch(:application)}".squish.downcase.gsub(/[\s|-]/, '_')
      end

      def user_app_env_underscore_short_char_safe
        user_app_env_underscore_short.squish.downcase.gsub(/[\s|-]/, '_')
      end

      def app_env_underscore
        "#{fetch(:application)}_#{environment}".squish.downcase.gsub(/[\s|-]/, '_')
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
        if !fetch(:rails_env).nil?
          fetch(:rails_env)
        elsif !fetch(:rack_env).nil?
          fetch(:rack_env)
        elsif !fetch(:stage).nil?
          fetch(:stage)
        else
          info '---------------------------------------------------------------'
          info '- Stage, rack or rails environment isn\'t set in               -'
          info '- :stage, :rails_env or :rack_env, defaulting to \'production\' -'
          info '---------------------------------------------------------------'
          'production'
        end
      end

      def template_to_s_io(template_file)
        fail "Cannot find template #{template_file}" unless File.exist?(template_file)
        StringIO.new(ERB.new(File.read(template_file)).result(binding))
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
