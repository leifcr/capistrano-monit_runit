namespace :load do
  task :defaults do
    set :pids_path,    proc { shared_path.join('pids') }
    set :sockets_path, proc { shared_path.join('sockets') }
  end
end

desc 'Get a list over Sudoers entries to add to a file in sudoers.d'
task :sudoers do
  run_locally do
    info '--- Copy the information below into a a file in sudoers.d ---'
  end
end
