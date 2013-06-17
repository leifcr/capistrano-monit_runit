module Capistrano
  module BaseHelper

    ## 
    # Automatically sets the environment based on presence of
    # :stage (multistage)
    # :rails_env 
    # RAILS_ENV variable; 
    # 
    # Defaults to "production" if not found
    #
    def environment
      if exists?(:stage)
        stage
      elsif exists?(:rails_env)
        rails_env
      elsif(ENV['RAILS_ENV'])
        ENV['RAILS_ENV']
      else
        puts "--------------------------------------------------------------"
        puts "- Rails environment or stage isn't set, defaulting to \"production\""
        puts "--------------------------------------------------------------"
        "production"
      end
    end

    ##
    # Return expanded path for templates
    # a path called templates must exist when using Capistrano::BaseHelper
    #
    def templates_path
      e = File.join(File.dirname(__FILE__),"../templates")
      File.expand_path(e)
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
    # @user_sudo use sudo or not...
    # 
    def generate_and_upload_config(local_file, remote_file, use_sudo=false)
      temp_file  = '/tmp/' + File.basename(local_file)
      erb_buffer =  Capistrano::BaseHelper::parse_config(local_file)
      # write temp file
      File.open(temp_file, 'w+') { |f| f << erb_buffer }
      # upload temp file
      upload temp_file, temp_file, :via => :scp
      # create any folders required
      run "#{use_sudo ? sudo : ""} mkdir -p #{Pathname.new(remote_file).dirname}"
      # move temporary file to remote file
      run "#{use_sudo ? sudo : ""} mv #{temp_file} #{remote_file}"
      # remove temp file
      `rm #{temp_file}`
    end

    ##
    # Execute a rake taske using bundle and the proper env.
    # run_rake db:migrate
    #
    def run_rake(task)
      run "cd #{current_path} && RAILS_ENV=#{environment} bundle exec rake #{task}"
    end

  end
end
