# frozen_string_literal: true

namespace :sidekiq do
  desc "Sidekiq stop"
  task :stop do
    puts "#### Trying to stop Sidekiq Now !!! ####"
    system "sidekiqctl stop /var/www/decidim/shared/tmp/pids/sidekiq-0.pid" # stops sidekiq process here
  end

  desc "Sidekiq start"
  task :start do
    puts "Starting Sidekiq..."
    system "bundle exec sidekiq  --index 0 --pidfile /var/www/decidim/shared/tmp/pids/sidekiq-0.pid --environment production  --logfile /var/www/decidim/shared/log/sidekiq.log -d"
  end

  desc "Sidekiq restart"
  task :restart do
    puts "#### Trying to restart Sidekiq Now !!! ####"
    Rake::Task["sidekiq:stop"].invoke
    Rake::Task["sidekiq:start"].invoke
    puts "#### Sidekiq restarted successfully !!! ####"
  end
end
