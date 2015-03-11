module Capistrano
  module DSL
    module BasePaths
      # user_app_env_path in basehelper 0.x / capistrano 2.x version
      def user_app_env_folder
        File.join(fetch(:user), "#{fetch(:application)}_#{environment}")
      end

      def user_app_env_file_name
        "#{fetch(:user)}_#{fetch(:application)}_#{environment}"
      end
    end
  end
end