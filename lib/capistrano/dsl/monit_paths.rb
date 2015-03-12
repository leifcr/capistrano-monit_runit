module Capistrano
  module DSL
    ##
    # Paths and filenames for monit
    module MonitPaths

      # Folder should belong to root:root
      def monit_etc_path
        File.join("/etc", "monit")
      end

      # This folder must be writable by the user group deploy
      # and ownership should be root:deploy
      def monit_etc_conf_d_path
        File.join(monit_etc_path, "conf.d")
      end

      # This file must have mode 0700 and belong to root!
      def monit_monitrc_file
        File.join(monit_etc_path, "monitrc")
      end

      # The symlink will belong to the deploy user
      def monit_etc_app_symlink
        File.join(monit_etc_conf_d_path, "#{user_app_env_file_name}.conf")
      end
    end
  end
end
