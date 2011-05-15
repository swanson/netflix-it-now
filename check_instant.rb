require 'rubygems'
require 'oauth'
require 'oauth-keys'
require 'nokogiri'
require 'open-uri'

def call_api(url)
  request = OAuth::RequestProxy.proxy \
        "method"        => "GET",
        "uri"           => url,
        "parameters"    => {"oauth_consumer_key"        => OAuthKeys::ConsumerKey,
                            "oauth_signature_method"    => "HMAC-SHA1",
                            "oauth_nonce"               => OAuth::Helper.generate_key,
                            "oauth_timestamp"           => OAuth::Helper.generate_timestamp}
  # sign the request
  request.sign! :consumer_secret => OAuthKeys::ConsumerSecret

  # make the API call
  return Nokogiri::XML(open(request.signed_uri))
end

def check_instant(title_id)
    format_data = call_api("http://api.netflix.com/catalog/titles/movies/#{title_id}/format_availability")

    # check for instant streaming
    if format_data.xpath('//delivery_formats/availability/category[@term="instant"]').size > 0
      movie_data = call_api("http://api.netflix.com/catalog/titles/movies/#{title_id}")
      
      return {
        'title' => movie_data.xpath('//title/@regular').first.value,
        'poster_url' => movie_data.xpath('//box_art/@large').first.value,
        'link_url' => movie_data.xpath('//link[@title="web page"]/@href').first.value,
        'is_instant' => true
      }
    else
      return {
        'is_instant' => false
      }
    end
end


