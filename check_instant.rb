require 'rubygems'
require 'oauth'
require 'oauth-keys'
require 'nokogiri'
require 'open-uri'

def check_instant(title_id)
    # make a OAuth request object
    request = OAuth::RequestProxy.proxy \
        "method"        => "GET",
        "uri"           => "http://api.netflix.com/catalog/titles/movies/#{title_id}/format_availability",
        "parameters"    => {"oauth_consumer_key"        => OAuthKeys::ConsumerKey,
                            "oauth_signature_method"    => "HMAC-SHA1",
                            "oauth_nonce"               =>  OAuth::Helper.generate_key,
                            "oauth_timestamp"           => OAuth::Helper.generate_timestamp}
    # sign the request
    request.sign! \
        :consumer_secret => OAuthKeys::ConsumerSecret

    # make the API call
    info = Nokogiri::XML(open(request.signed_uri))

    # check for instant streaming
    return info.xpath('//delivery_formats/availability/category[@term="instant"]').size > 0
end


