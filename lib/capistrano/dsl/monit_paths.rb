module Capistrano
  module DSL
    ##
    # Paths and filenames for monit
    module MonitPaths
      def monit_etc_app_symlink
        File.join(fetch(:monit_etc_conf_d_path), "#{user_app_env_file_name}.conf")
      end
    end
  end
end
