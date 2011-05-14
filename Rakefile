require 'pony'

task :cron do
  puts "Running cron"
  Rake::Task['email:send'].invoke('matt@test.com', 'sup')
end

namespace :email do
  desc 'Send an email with Pony via SendGrid'
  task :send, :email, :msg do |cmd, args|
    puts "Sent #{args[:msg]} to #{args[:email]}"
  end
end

namespace :netflix do
  task :check_instant, :movie_id, :is_series do |cmd, args|
    puts "check netflix api for #{args[:movie_id]}"
  end
end
