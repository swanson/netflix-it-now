require 'pony'
require 'check_instant'
require 'mongo'
require 'erb'

def connect_to_mongo
  puts "Connecting to MongoDB"
  uri = URI.parse(ENV['MONGOHQ_URL'])
  conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
  db = conn.db(uri.path.gsub(/^\//, ''))
  $coll = db.collection('netflix-users')
end

def load_email_template
  $template = File.read('views/mailers/new_movies.html.erb')
end

def send_mail(email, movies)
  puts "Sending email to #{email}"
  Pony.mail(
    :from => 'netflix-instant-reminder',
    :to => email,
    :subject => 'Netflix Instant Reminder',
    :headers => { 'Content-Type' => 'text/html' },
    :body => ERB.new($template).result(binding),
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
  load_email_template

  movie_cache = Hash.new
  movie_details = Hash.new

  $coll.find().each do |user|
    puts "Checking for #{user['email']}"
    new_movies = Array.new
    ids_to_remove = Array.new

    next if user['verified'] == 0 || user['verified'].nil?

    user['tracked_movies'].each do |id|
      if movie_cache.has_key?(id)
        puts 'Found it in the cache'
        
        if movie_cache[id]
          ids_to_remove << id
          new_movies << movie_details[id]
        end
      else
        puts 'Checking API'
        movie_info = check_instant(id)

        movie_cache[id] = movie_info['is_instant']
        movie_details[id] = movie_info
        
        if movie_info['is_instant']
          ids_to_remove << id
          new_movies << movie_info
        end
      end
    end

    user['tracked_movies'] = user['tracked_movies'] - ids_to_remove
    $coll.update({"_id" => user["_id"]}, user)
    
    if new_movies.length > 0
      send_mail(user['email'], new_movies)
    end
  end
end

