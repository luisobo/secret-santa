#!/usr/bin/env ruby

require 'securerandom'
require 'net/https'
require 'json'

names = ARGV

couples = JSON.parse(File.read("./couples.json")).to_h
past = JSON.parse(File.read("./past.json"))



def valid?(results, couples, past)

  results.each do |k, v|

    if couples[k] == v || couples[v] == k
      return false
    end

    past.each do |p|
      if p[k] == v
        return false
      end
    end
  end

  return true
end

if names.count < 2
  puts "usage: ONE_TIME_SECRET_USERNAME=Your_OTS_username ONE_TIME_SECRET_API_KEY=Your_OTS_api_key #{__FILE__} name1 name2 [name3 ...]"
  exit 1
end

valid = false
results = {}
while !valid do
  names.shuffle!
  results = names.zip(names.rotate).to_h

  if valid?(results, couples, past)
    valid = true
    puts "VALID"
  else
    puts "INVALID"
  end

end

# puts results
# exit 1

results.each do |k, v|

  uri = URI('https://onetimesecret.com/api/v1/share')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Post.new("/api/v1/share")
  request.basic_auth(ENV['ONE_TIME_SECRET_USERNAME'], ENV['ONE_TIME_SECRET_API_KEY'])
  request.body = "secret=You are the secret santa of: #{v}"
  response = http.request(request)

  secret_key = JSON.parse(response.body)['secret_key']

  puts "Secret for #{k}: " + 'https://onetimesecret.com/secret/' + secret_key

end

past << results
File.write("./past.json", JSON.generate(past))


