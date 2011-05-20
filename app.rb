require 'sinatra'
require 'uri'
require 'mongo'
require 'json'
require 'rack/cors'

class NetflixItNow < Sinatra::Application
  set :static, true
  set :public, 'public'
  enable :sessions

  use Rack::Cors do |cfg|
    cfg.allow do |allow|
      allow.origins 'movies.netflix.com'

      allow.resource '/track', :methods => [:post]
      allow.resource '/tracked', :methods => [:get]
    end
  end

  configure do
    uri = URI.parse(ENV['MONGOHQ_URL'])
    conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
    db = conn.db(uri.path.gsub(/^\//, ''))
    $coll = db.collection('netflix-users')
  end

  helpers do
    def base_url
      @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
    end
  end

  get '/' do
    erb :index
  end

  get '/buttonizer.user.js' do
    content_type :js
    erb :buttonizer
  end

  get '/verify/:email/:guid' do
    user = $coll.find("email" => params[:email]).first
    if user["_id"].to_s == params[:guid]
      user['verified'] = 1
      $coll.update({"_id" => user["_id"]}, user)
      return 'Success!'
    else
      return 'Failed...please contact support at /dev/null'
    end
  end

  post '/login' do
    session[:email] = params[:email]
    user = $coll.find("email" => session[:email]).first
    if user.nil?
      guid = $coll.insert({
        "email" => session[:email],
        "tracked_movies" => [],
        "verified" => 0
      })
      verify_link = @base_url.to_s + "/verify/#{session[:email]}/#{guid}"
      Pony.mail(
        :from => 'netflix-instant-reminder',
        :to => session[:email],
        :subject => 'Netflix Instant Reminder - Verify your account',
        :headers => { 'Content-Type' => 'text/html' },
        :body => erb('mailers/verify.html.erb'),
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
        })

    end
    redirect '/'
  end

  get '/logout' do
    session[:email] = nil
    redirect '/'
  end

  post '/track' do
    unless session[:email]
      halt 401
    end
    user = $coll.find("email" => session[:email]).first
    unless user.nil?
      user['tracked_movies'] << params[:movie_id].to_i
      user['tracked_movies'].uniq!
      $coll.update({"_id" => user["_id"]}, user)
    else
      halt 401
    end
    return
  end

  get '/tracked' do
    unless session[:email]
      # no user given
      halt 401
    end
    user = $coll.find("email" => session[:email]).first
    unless user.nil?
      # set the cache to expire in a day
      headers["Cache-Control"] = "public, max-age=" + (60*60*24).to_s
      return {:tracked => user["tracked_movies"]}.to_json
    else
      # no user found
      halt 401
    end
  end
end

# vim:ts=2:sw=2:sts=2
