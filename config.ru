require 'app'
require 'rack/offline'

map "/application.manifest" do
  offline = Rack::Offline.new :cache => true do
    cache "/tracked"
    network "/"
  end
  run offline
end

run NetflixItNow
