namespace :load do
  task :defaults do
    set :pids_path,    Proc.new { File.join(fetch(:shared_path), "pids") }
    set :sockets_path, Proc.new { File.join(fetch(:shared_path), "sockets") }
  end
end
