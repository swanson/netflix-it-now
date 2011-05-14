require 'sinatra'

class NetflixItNow < Sinatra::Base
  set :static, true
  set :public, 'public'

  get '/' do
    "netflix it now!"
  end
end
