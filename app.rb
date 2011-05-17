require 'sinatra'
require 'uri'
require 'mongo'
require 'json'
require 'rack/cors'

class NetflixItNow < Sinatra::Base
  set :static, true
  set :public, 'public'

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

  get '/' do
    erb :index
  end

  post '/track' do
    user = $coll.find("email" => params[:email]).first
    unless user.nil?
      user['tracked_movies'] << params[:movie_id].to_i
      user['tracked_movies'].uniq!
      $coll.update({"_id" => user["_id"]}, user)
    else
      $coll.insert({
                    "email" => params[:email], 
                    "tracked_movies" => [params[:movie_id].to_i,]
      })
    end
    return 200
  end

  get '/tracked' do
    # FIXME: use cookies or something to get the user
    user = $coll.find("email" => "jevin@purdue.edu").first
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
