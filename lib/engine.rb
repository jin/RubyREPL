require 'twitter'
require 'shikashi'
require_relative 'config'

module RubyREPL
  class Engine

    def initialize
      user_config = RubyREPL::Configuration.config
      config_strings = ["consumer_key", 
                        "consumer_secret", 
                        "access_token", 
                        "access_token_secret"]

      @stream_client = Twitter::Streaming::Client.new do |config|
        config_strings.each { |str| config.send("#{str}=", user_config[str]) }
      end

      @rest_client = Twitter::REST::Client.new do |config|
        config_strings.each { |str| config.send("#{str}=", user_config[str]) }
      end
    end

    def evaluate_tweet(tweet)
      begin
        sandbox = Shikashi::Sandbox.new
        priv = Shikashi::Privileges.new
        priv.allow_method :"+"
        priv.allow_method :"*"
        eval_output = sandbox.run(tweet.text.split(' ')[1..-1].join(' '), priv) 
        # eval_output = eval tweet.text.split(' ')[1..-1].join(' ')
        @rest_client.update("@#{tweet.user.screen_name} #{eval_output}",
                           :in_reply_to_status => tweet)
      rescue Exception => exc
        @rest_client.update(
          "@#{tweet.user.screen_name} I'm sorry, I don't understand your input!", 
          :in_reply_to_status => tweet)
        p exc
      end
    end

    def start_stream
      @stream_client.user(:with => "user") do |object|
        p object
        evaluate_tweet(object) if object.is_a?(Twitter::Tweet) && 
                                  object.user.screen_name != "RubyREPL"
      end
    end

  end
end

