set :application, "Npedia"
set :user, "admin"
set :stages, %w(chapbookpro production)
set :default_stage, 'chapbookpro'
require 'capistrano/ext/multistage'

set :repository,  "svn://crunchytoast.unfuddle.com/svn/crunchytoast_npedia/"
set :deploy_to, "/home/npedia.org"
set :mongrel_config, "#{current_path}/config/mongrel_cluster.yml"

set :use_sudo, true
set :keep_releases, 3
set :deploy_via, :export
#set :deploy_via, :remote_cache
set :rails_version, fetch(:rails_version, "8331") # v2.0.1

set(:deploy_to) { "/path/to/#{application}/#{stage}" }

# ==.=-.=.-.-..=..=-.=.-.-..=.
# ROLES
# ==.=-.=.-.-..=..=-.=.-.-..=.

role :app, "crunchytoast.com"
role :web, "crunchytoast.com"
role :db,  "mikan.crunchytoast.com", :primary => true

task :chapbookpro do
  server "localhost", :app, :web, :db, :primary => true
  set  :stage, :chapbookpro
end

task :production do
  role :web, 'crunchytoast.com'
  role :app, 'crunchytoast.com'
  role :db,  'mikan.crunchytoast.com', :primary => true
  set  :stage, :production
end


# ==.=-.=.-.-..=..=-.=.-.-..=.
# TASKS
# ==.=-.=.-.-..=..=-.=.-.-..=.

namespace :deploy do

  desc "Runs after every successful deployment" 
  task :after_default do
    puts stage
    cleanup
  end
  
  task :after_update_code do
    mongrel_config = "#{current_path}/config/production.mongrel_cluster.yml"
    run "cp #{mongrel_config} #{release_path}/config/mongrel_cluster.yml"
    run <<-CMD
      cd #{release_path} && rake deploy_rails REVISION=#{rails_version}
    CMD
  end
  
  desc "Restarts sphinx, memcached and the pack of mongrels"
  task :restart do
    run "rake ts:rebuild"
    run "rake memcached:restart"
    restart_mongrel_cluster
  end
  
  namespace :web do

    desc "Serve up a custom maintenance page."
    task :disable, :roles => :web do
      require 'erb'
      on_rollback { run "rm #{shared_path}/system/maintenance.html" }
      
      reason      = ENV['REASON']
      deadline    = ENV['UNTIL']
      
      template = File.read("app/views/admin/maintenance.html.erb")
      page = ERB.new(template).result(binding)
      
      put page, "#{shared_path}/system/maintenance.html", 
                :mode => 0644
    end
  end
end

namespace :deploy do
  
  task :copy_database_configuration do
    production_db_config = "/npedia.org/production.database.yml"
    run "cp #{production_db_config} #{release_path}/config/database.yml"
  end
  
  after "deploy:update_code", "deploy:copy_database_configuration"
end


namespace :deploy do
  
  task :upload_cluster_configuration, :roles => :app do
    cluster_config = <<-CMD
      port: 8000
      servers: 4
      address: 127.0.0.1
      cwd: #{deploy_to}/current
      pid_file: tmp/pids/#{application}-mongrel.pid
      user: capistrano
      group: capistrano
      environment: production
    CMD
    put cluster_config, "#{release_path}/config/mongrel_cluster.yml"
  end
  
  after "deploy:update_code", "deploy:upload_cluster_configuration"
end


namespace :assets do

  task :symlink, :roles => :app do
    assets.create_dirs
    run <<-CMD
      rm -rf  #{release_path}/index &&
      rm -rf  #{release_path}/public/images/pictures &&
      ln -nfs #{shared_path}/index #{release_path}/index &&
      ln -nfs #{shared_path}/pictures #{release_path}/public/images/pictures
    CMD
  end
  
  task :create_dirs, :roles => :app do
    %w(index pictures).each do |name|
      run "mkdir -p #{shared_path}/#{name}"
    end
  end

end

after "deploy:update_code", "assets:symlink"

after "deploy:setup", "create_page_cache"
task :create_page_cache, :roles => :app do
  run "umask 02 && mkdir -p #{shared_path}/cache"
end

after "deploy:update_code","symlink_cache_dir"
task :symlink_cache_dir, :roles => :app do
  run <<-CMD
    cd #{release_path} &&
    ln -nfs #{shared_path}/cache #{release_path}/public/cache
  CMD
end


# default behavior is to flush page cache on deploy
set :flush_cache, true

desc "Retain the page cache"
task :keep_page_cache do
  set :flush_cache, false
end

after "deploy:cleanup", "flush_page_cache"
task :flush_page_cache, :roles => :app do
  if flush_cache
    run <<-CMD
      rm -rf #{shared_path}/cache/*
    CMD
  end
end

def run_with_prompt(command, expected_question)
  run command, :once => true do |channel, stream, output| 
    if output =~ /#{expected_question}/ 
      answer = Capistrano::CLI.ui.ask(expected_question) 
      channel.send_data(answer + "\n") 
    else 
      # allow the default callback to be processed 
      Capistrano::Configuration.default_io_proc.call(channel, stream, output) 
    end
  end
end

def template_engine(template, partial=nil, stylesheet=nil, opts={})
  require 'erb'
  unless opts.empty?
    set :title, opts[:title]
    set :heading, opts[:heading]
    set :body, ERB.new(File.read(partial)).result(binding)
  end
  ERB.new(File.read(template)).result(binding)
end

def error_template_path(filename)
  ["config", "deploy", "errors", filename].join("/")
end

task :create_error_pages, :roles => [:web, :app] do
  errors = { 
    "404" => { "title"   => "Page Not Found", 
               "heading" => "Page Not Found" },
    "422" => { "title"   => "Oops!", 
               "heading" => "The data you submitted was invalid." },
    "500" => { "title"   => "Oops!", 
               "heading" => "Kaboom!" }
  }
  errors.each_key do |error|
    template   = error_template_path("error.html.erb")
    partial    = error_template_path("_#{error}.html.erb")
    stylesheet = error_template_path("error.css")
    put template_engine(template, partial, stylesheet, 
                        :title => errors[error]["title"], 
                        :heading => errors[error]["heading"]
                       ), "#{current_path}/public/#{error}.html", 
                       :mode => 0644
  end
end

desc "Open script/console on the remote machine"
task :console, :roles => :app do
  input = ''
  cmd = "cd #{current_path} && ./script/console #{ENV['RAILS_ENV']}"
  run cmd, :once => true do |channel, stream, data|
    next if data.chomp == input.chomp || data.chomp == ''
    print data
    channel.send_data(input = $stdin.gets) if data =~ /^(>|\?)>/
  end
end

desc "Echo the remote server PATH"
task :path, :roles => :app do
  run "echo $PATH"
  run "which ruby"
end

desc "Watch multiple log files at the same time"
task :tail_log, :roles => :app do
  stream "tail -f #{shared_path}/log/production.log"
end

desc "Start the mongrels"
task :start_mongrel_cluster do
  sudo "mongrel_rails cluster::start -C #{mongrel_config}" 
end

desc "Stop the mongrels"
task :stop_mongrel_cluster do
  sudo "mongrel_rails cluster::stop -C #{mongrel_config}" 
end

desc "Restart the mongrels"
task :restart_mongrel_cluster do
  stop_mongrel_cluster
  sudo "rm -rf #{current_path}/tmp/pids/mongrel.*.pid"
  start_mongrel_cluster
end
