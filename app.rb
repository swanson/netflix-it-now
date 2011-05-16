require 'sinatra'
require 'uri'
require 'mongo'

class NetflixItNow < Sinatra::Base
  set :static, true
  set :public, 'public'

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
end
