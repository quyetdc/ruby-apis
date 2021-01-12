# README
# simple curl test
# curl -i http://localhost:4567/users/thibault \
#      -H "Accept: application/xml"
#
#
# curl -i http://localhost:4567/users \
#      -H "Accept: application/json"

# webapi.rb
require 'sinatra'
require 'json'
require 'gyoku'

users = {
  thibault: { first_name: 'Thibault', last_name: 'Denizet', age: 25 },
  simon:    { first_name: 'Simon', last_name: 'Random', age: 26 },
  john:     { first_name: 'John', last_name: 'Smith', age: 28 }
}

helpers do

  def json_or_default?(type)
    ['application/json', 'application/*', '*/*'].include?(type.to_s)
  end

  def xml?(type)
    type.to_s == 'application/xml'
  end

  def accepted_media_type
    return 'json' unless request.accept.any?

    request.accept.each do |mt|
      return 'json' if json_or_default?(mt)
      return 'xml' if xml?(mt)
    end

    halt 406, 'Not Acceptable'
  end

  def type
    @type ||= accepted_media_type
  end

  def send_data(data = {})
    if type == 'json'
      content_type 'application/json'
      data[:json].call.to_json if data[:json]
    elsif type == 'xml'
      content_type 'application/xml'
      Gyoku.xml(data[:xml].call) if data[:xml]
    end
  end

end

get '/' do
  'Master Ruby Web APIs - Chapter 2'
end

get '/users' do
  send_data(json: -> { users.map { |name, data| data.merge(id: name) } },
            xml:  -> { { users: users } })
end

get '/users/:first_name' do |first_name|
  send_data(json: -> { users[first_name.to_sym].merge(id: first_name) },
            xml:  -> { { first_name => users[first_name.to_sym] } })
end


# curl -I -v http://localhost:4567/users
head '/users' do
  send_data
end


# curl POST -v http://localhost:4567/users \
#      -H "Content-Type: application/json" \
#      -d '{"first_name":"Samuel","last_name":"Da Costa","age":19}'
post '/users' do
  user = JSON.parse(request.body.read)
  users[user['first_name'].downcase.to_sym] = user

  url = "http://localhost:4567/users/#{user['first_name']}"
  response.headers['Location'] = url

  status 201
end


# curl -X PUT -v http://localhost:4567/users/jane \
#      -H "Content-Type: application/json" \
#      -d '{"first_name":"Jane","last_name":"Smiht","age":24}'
put '/users/:first_name' do |first_name|
  user = JSON.parse(request.body.read)
  existing = users[first_name.to_sym]
  users[first_name.to_sym] = user
  status existing ? 204 : 201
end


# curl -X PATCH -v http://localhost:4567/users/thibault \
#      -H "Content-Type: application/json" \
#      -d '{"age":26}'
#
patch '/users/:first_name' do |first_name|
  type = accepted_media_type

  user_client = JSON.parse(request.body.read)
  user_server = users[first_name.to_sym]

  user_client.each do |key, value|
    user_server[key.to_sym] = value
  end

  send_data(json: -> { user_server.merge(id: first_name) },
            xml:  -> { { first_name => user_server } })
end


# curl -X DELETE -v http://localhost:4567/users/thibault
delete '/users/:first_name' do |first_name|
  users.delete(first_name.to_sym)
  status 204
end

# curl -v -X OPTIONS http://localhost:4567/users
options '/users' do
  response.headers['Allow'] = 'HEAD,GET,POST'
  status 200
end

options '/users/:first_name' do
  response.headers['Allow'] = 'GET,PUT,PATCH,DELETE'
  status 200
end