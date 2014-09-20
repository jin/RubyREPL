require 'twitter'
require 'yaml'

user_config = YAML::load_file "user_config.yml"

client = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = user_config.consumer_key
  config.consumer_secret     = user_config.consumer_secret 
  config.access_token        = user_config.access_token 
  config.access_token_secret = user_config.access_token_secret 
end

topics = ["ruby"]
client.filter(:track => topics.join(",")) do |object|
  puts object.text if object.is_a?(Twitter::Tweet)
end

client.user do |object|
  case object
  when Twitter::Streaming::Event
    puts "It's a tweet!"
  when Twitter::Streaming::StallWarning
    warn "Falling behind!"
  end
end
