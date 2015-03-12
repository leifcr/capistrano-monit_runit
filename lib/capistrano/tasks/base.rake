namespace :load do
  task :defaults do
    set :pids_path,    proc { shared_path.join('pids') }
    set :sockets_path, proc { shared_path.join('sockets') }
  end
end
