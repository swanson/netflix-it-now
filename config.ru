require 'app'
require 'rack/offline'

map "/application.manifest" do
  offline = Rack::Offline.configure do
    cache "/tracked"
    network "/"
  end
  run offline
end

run NetflixItNow
