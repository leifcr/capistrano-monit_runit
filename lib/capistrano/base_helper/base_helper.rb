Capistrano::Configuration.instance(true).load do
  _cset :pids_path, File.join(fetch(:shared_path), "pids")
  _cset :sockets_path, File.join(fetch(:shared_path), "sockets")
  namespace :base_helper do
    desc "[internal] set the capistrano instance in Capistrano::BaseHelper module"
    task :set_capistrano_instance do
      Capistrano::BaseHelper::set_capistrano_instance(self)
    end    
  end
  
  on :start, "base_helper:set_capistrano_instance"
end

module Capistrano
  module BaseHelper
    @@capistrano_instance
    module_function

    def set_capistrano_instance(cap_instance)
      @@capistrano_instance = cap_instance
    end

    def get_capistrano_instance
      @@capistrano_instance
    end

    def user_app_env_underscore
      "#{@@capistrano_instance.fetch(:user)}_#{@@capistrano_instance.fetch(:application)}_#{environment}"
    end

    def user_app_env_underscore_short
      "#{@@capistrano_instance.fetch(:user)[0...1]}_#{environment[0...1]}_#{@@capistrano_instance.fetch(:application)}"
    end

    def user_app_env_path
      File.join(get_capistrano_instance.fetch(:user), "#{get_capistrano_instance.fetch(:application)}_#{environment}")
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
      if @@capistrano_instance.exists?(:rails_env)
        @@capistrano_instance.fetch(:rails_env)
      elsif @@capistrano_instance.exists?(:rack_env)
        @@capistrano_instance.fetch(:rack_env)        
      elsif @@capistrano_instance.exists?(:stage)
        @@capistrano_instance.fetch(:stage)
      elsif(ENV['RAILS_ENV'])
        ENV['RAILS_ENV']
      else
        puts "------------------------------------------------------------------"
        puts "- Stage, rack or rails environment isn't set in                  -"
        puts "- :stage or :rails_env or :rack_env, defaulting to 'production'  -"
        puts "------------------------------------------------------------------"
        "production"
      end
    end

    ##
    # parse a erb template and return the result
    #
    def parse_config(file)
      require 'erb'  #render not available in Capistrano 2
      template  = File.read(file)          # read it
      returnval = ERB.new(template).result(binding)   # parse it
      return returnval
    end

    ##
    # Prompts the user for a message to agree/decline
    #
    def ask(message, default=true)
      Capistrano::CLI.ui.agree(message)
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
      @@capistrano_instance.run "#{use_sudo ? @@capistrano_instance.sudo : ""} mkdir -p #{Pathname.new(remote_file).dirname}; #{use_sudo ? "sudo" : ""} mv #{temp_file} #{remote_file}"
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
