# webapi_caching.rb
require 'sinatra'
require 'json'
require 'digest/sha1'

users = {
  thibault: { first_name: 'Thibault', last_name: 'Denizet', age: 25 },
  simon:    { first_name: 'Simon', last_name: 'Random', age: 26 },
  john:     { first_name: 'John', last_name: 'Smith', age: 28 }
}

before do
  content_type 'application/json'
  cache_control max_age: 60
end

get '/users' do
  # sleep 3

  etag Digest::SHA1.hexdigest(users.to_s)
  # sleep 3

  users.map { |name, data| data }.to_json
end