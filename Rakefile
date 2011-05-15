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

def send_mail(email, msg)
  puts "Sending #{msg} to #{email}"
  Pony.mail(
    :from => 'netflix-instant-reminder',
    :to => email,
    :subject => 'Netflix Instant Reminder',
    :body => msg,
    :port => '587',
    :via => :smtp,
    :via_options => {
      :address => ENV['EMAIL_SERVICE'],
      :port => '587',
      :enable_starttls_autp => true,
      :user_name => ENV['SENDGRID_USERNAME'],
      :password => ENV['SENDGRID_PASSWORD'],
      :authentication => :plain,
      :domain => ENV['SENDGRID_DOMAIN']
    }
  )
end

task :cron do
  puts "Running cron"
  connect_to_mongo

  movie_cache = Hash.new
  $coll.find().each do |user|
    puts "Checking for #{user['email']}"
    new_movies = Array.new
    user['tracked_movies'].each do |id|
      if movie_cache.has_key?(id)
        puts 'Found it in the cache'
        
        if movie_cache[id]
            new_movies << id
        end
      else
        puts 'Checking API'
        
        is_instant = check_instant(id)
        movie_cache[id] = is_instant
        
        if is_instant
          new_movies << id
        end
      end
    end

    user['tracked_movies'] = user['tracked_movies'] - new_movies
    $coll.update({"_id" => user["_id"]}, user)
    
    if new_movies.length > 0
      send_mail(user['email'], new_movies.to_s)
    end
  end
end

