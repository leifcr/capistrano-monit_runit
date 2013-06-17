Capistrano::Configuration.instance(true).load do
  _cset :runit_dir, defer { "#{shared_path}/runit" }

  namespace :runit do
    desc "Setup runit directories"
    task :setup, :roles => [:app, :db] do
      run "[ -d #{runit_dir}/.env ] || mkdir -p #{runit_dir}/.env"
      run "echo $HOME > #{runit_dir}/.env/HOME"
    end
  end
end

module Capistrano
  module RunitBase

    def service_path(service_name)
      "#{runit_dir}/#{service_name}"
    end

    def create_service_dir(service_name)
      run "[ -d #{service_path} ] || mkdir -p #{service_path}"
    end

    ##
    # application name should be "app-environment" or similar in case you deploy staging/production to same host
    def enable_app_services_as_user(application_name, user)
      # SEE http://off-the-stack.moorman.nu/posts/5-user-services-with-runit/ for info on scripts
      run "sudo mkdir -p /etc/service/#{user}/#{application_name}/"
      run_file_data = <<-EOF
# Run services for #{application_name} as #{user}
!/bin/sh -e
# exec 2>&1 exec chpst -u #{user} runsvdir "#{runit_dir}" 'log: .......................'
EOF
      finish_file_data = <<-EOF
#!/bin/sh
sv -w600 force-stop #{runit_dir}/*
sv exit #{runit_dir}*
EOF
chmod u+x /etc/sv/user/rico/finish
      put run_file_data,    "/etc/services/#{user}/#{application_name}/run"
      put finish_file_data, "/etc/services/#{user}/#{application_name}/finish"
      run "sudo chown deploy:root /etc/services/#{user}/#{application_name}/run"
      run "sudo chown deploy:root /etc/services/#{user}/#{application_name}/finish"
      run "sudo chmod u+x /etc/services/#{user}/#{application_name}/run"
      run "sudo chmod u+x /etc/services/#{user}/#{application_name}/finish"
      run "sudo chmod g+x /etc/services/#{user}/#{application_name}/run"
      run "sudo chmod g+x /etc/services/#{user}/#{application_name}/finish"
    end

    def enable_app_services_at_boot(application_symlink, service_name)
      # symlink the above run to a dir?
      # ???
    end

    def start_service_once(service_name)
      run "[ ! -h #{service_path}/run ] || sv once #{service_path}"  
    end

    def start_service(service_name)
      run "[ ! -h #{service_path}/run ] || sv start #{service_path}"  
    end

    def stop_service(service_name)
      run "[ ! -h #{service_path}/run ] || sv stop #{service_path}"  
    end

    def restart_service(service_name)
      run "[ ! -h #{service_path}/run ] || sv restart #{service_path}"  
    end

    def disable_service(service_name)  
      run "[ ! -h #{service_path}/run ] || sv stop #{service_path} && rm -f #{service_path}/run && rm -f #{service_path}/finish"
    end

    def enable_service(service_name, symlink_finish = nil)
      run "cd #{service_path} && [ -h ./run ] || ln -sf #{service_path}/#{service_name}_run ./run"
      run "cd #{service_path} && [ -h ./finish ] || ln -sf #{service_path}/#{service_name}_finish ./run" unless symlink_finish.nil?
    end

  end
end
