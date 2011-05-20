require 'sinatra'
require 'uri'
require 'mongo'
require 'json'
require 'rack/cors'
require 'pony'
require 'crxmake'

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

    def browser
      agent = request.env["HTTP_USER_AGENT"]
      if agent =~ /Chrome/
        return :chrome
      elsif agent =~ /Firefox/
        return :firefox
      else
        return :other
      end
    end

    def chrome_bundle
      t = Tempfile.new(["buttonizer-chrome-ext", ".crx"])
      CrxMake.make(
        :ex_dir => "./chrome-ext",
        :ex_buffers => [[erb(:buttonizer), "buttonizer.js"],],
        :crx_output => t.path
      )
      buf = IO.read(t.path)
      t.close
      @chrome_bundle ||= buf
    end
  end

  get '/' do
    erb :index
  end

  get '/buttonizer.user.js' do
    content_type :js
    erb :buttonizer
  end
  
  get '/buttonizer.crx' do
    content_type 'application/x-chrome-extension'
    return chrome_bundle
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

  get '/buttonizer.crx' do
    content_type 'application/x-chrome-extension'
    return chrome_bundle
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
      verify_link = "/verify/#{session[:email]}/#{guid}"
      Pony.mail(
        :from => 'netflix-instant-reminder',
        :to => session[:email],
        :subject => 'Netflix Instant Reminder - Verify your account',
        :headers => { 'Content-Type' => 'text/html' },
        :body => "Thanks for signing up. Just click the link below to verify that you want to receive emails.<br/><br/><a href=\"#{base_url}#{verify_link}\">#{base_url}#{verify_link}</a>",
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
      puts verify_link

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
      cache_control :public, :max_age => 60*60*24
      return {:tracked => user["tracked_movies"]}.to_json
    else
      # no user found
      halt 401
    end
  end
end

# vim:ts=2:sw=2:sts=2
