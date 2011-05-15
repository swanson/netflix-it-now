require 'pony'
require 'check_instant'
require 'mongo'

def connect_to_mongo
  puts "Connecting to MongoDB"
  uri = URI.parse(ENV['MONGOHQ_URL'])
  conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
  db = conn.db(uri.path.gsub(/^\//, ''))
  $coll = db.collection('netflix-users')
end

task :cron do
  puts "Running cron"
  connect_to_mongo
  $coll.find().each do |user|
    user['tracked_movies'].each do |id|
      if check_instant(id)
        Rake::Task['email:send'].invoke(user['email'], "Movie #{id} is done!")  
      end
    end
  end
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
