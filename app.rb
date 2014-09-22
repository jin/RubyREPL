require 'twitter'
require 'yaml'
require 'shikashi'

include Shikashi

user_config = YAML::load_file "user_config.yml"
@s = Sandbox.new
@priv = Privileges.new
@priv.allow_method :print

@stream_client = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = user_config["consumer_key"]
  config.consumer_secret     = user_config["consumer_secret"]
  config.access_token        = user_config["access_token"]
  config.access_token_secret = user_config["access_token_secret"]
end

@rest_client = Twitter::REST::Client.new do |config|
  config.consumer_key        = user_config["consumer_key"]
  config.consumer_secret     = user_config["consumer_secret"]
  config.access_token        = user_config["access_token"]
  config.access_token_secret = user_config["access_token_secret"]
end

def evaluate_tweet(tweet)
  begin
    eval_output = eval tweet.text.split(' ')[1..-1].join(' ') 
     
    # eval_output = @s.run(priv, tweet.text.split(' ')[1..-1].join(' '))
    @rest_client.update("@#{tweet.user.name} #{eval_output}")
  rescue Exception => exc
    @rest_client.update("@#{tweet.user.name} I'm sorry, I don't understand your input!")
  end
end

topics = ["repltweet"]
@stream_client.filter(:track => topics.join(",")) do |object|
  p object
  if object.is_a?(Twitter::Tweet)
    evaluate_tweet(object)
  end
end

