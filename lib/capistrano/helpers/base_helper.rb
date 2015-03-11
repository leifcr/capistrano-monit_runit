module Capistrano
  module BaseHelper
    def user_app_env_underscore
      "#{fetch(:user)}_#{fetch(:application)}_#{environment}"
    end

    def user_app_env_underscore_short
      "#{fetch(:user)[0...1]}_#{environment[0...1]}_#{fetch(:application)}"
    end

    def user_app_env_underscore_short_char_safe
      user_app_env_underscore_short.gsub!("-","_")
    end

    ##
    # Automatically sets the environment based on presence of
    # :stage (multistage)
    # :rails_env
    # RAILS_ENV variable;
    #
    # Defaults to "production" if not found
    #
    def environment
      if exists?(:rails_env)
        fetch(:rails_env)
      elsif exists?(:rack_env)
        fetch(:rack_env)
      elsif exists?(:stage)
        fetch(:stage)
      elsif(ENV['RAILS_ENV'])
        ENV['RAILS_ENV']
      else
        puts "------------------------------------------------------------------"
        puts "- WStage, rack or rails environment isn't set in                  -"
        puts "- :stage or :rails_env or :rack_env, defaulting to 'production'  -"
        puts "------------------------------------------------------------------"
        "production"
      end
    end

    def template_to_s(template_file)
      raise "Cannot find templte #{template_file}" unless File.exists?(template_file)
      ERB.new(File.read(config_file)).result(binding)
    end

    ##
    # parse a erb template and return the result
    #
    def parse_config(file)
      require 'erb'  #render not available in Capistrano 2
      template  = File.read(file)          # read it
      return ERB.new(template).result(binding)   # parse it
      return returnval
    end

    ##
    # Prompts the user for a message to agree/decline
    #
    def ask(message)
      @@capistrano_instance.ask(message)
    end

    ##
    # Generate a config file by parsing an ERB template and uploading the file
    # Fetches local file and uploads it to remote_file
    # Make sure your user has the right permissions.
    #
    # @local_file full path to local file
    # @remote_file full path to remote file
    # @use_sudo use sudo or not...
    #
    def generate_and_upload_config(local_file, remote_file, use_sudo=false)
      temp_file  = '/tmp/' + File.basename(local_file)
      erb_buffer =  Capistrano::BaseHelper::parse_config(local_file)
      # write temp file
      File.open(temp_file, 'w+') { |f| f << erb_buffer }
      # upload temp file
      @@capistrano_instance.upload temp_file, temp_file, :via => :scp
      # create any folders required,
      # move temporary file to remote file
      @@capistrano_instance.execute "#{use_sudo ? @@capistrano_instance.sudo : ""} mkdir -p #{Pathname.new(remote_file).dirname}; #{use_sudo ? "sudo" : ""} mv #{temp_file} #{remote_file}"
      # remove temp file
      `rm #{temp_file}`
    end

    ##
    # Execute a rake taske using bundle and the proper env.
    # run_rake db:migrate
    #
    def run_rake(task)
      @@capistrano_instance.run "cd #{@@capistrano_instance.current_path} && RAILS_ENV=#{Capistrano::BaseHelper.environment} bundle exec rake #{task}"
    end

    ##
    # Prepare a path with the given user and group name
    # @path the path to prepare
    # @user the user to chown the path
    # @group the group to chown the path
    # @use_sudo true/false for using sudo for all the commands

    def prepare_path(path, user, group, use_sudo = false)
      commands = []
      commands << "#{use_sudo ? @@capistrano_instance.sudo : ""} mkdir -p #{path}"
      commands << "#{use_sudo ? @@capistrano_instance.sudo : ""} chown #{user}:#{group} #{path} -R"
      commands << "#{use_sudo ? @@capistrano_instance.sudo : ""} chmod +rw #{path}"
      @@capistrano_instance.run commands.join(" &&")
    end

    ##
    # Check for file existance
    # See http://stackoverflow.com/questions/1661586/how-can-you-check-to-see-if-a-file-exists-on-the-remote-server-in-capistrano
    # Credits: Patrick Reagen / Knocte
    def remote_file_exists?(path)
      results = []
      @@capistrano_instance.invoke_command("if [ -e '#{path}' ]; then echo -n 'true'; fi") do |ch, stream, out|
        results << (out == 'true')
      end

      results == [true]
    end

  end
end
