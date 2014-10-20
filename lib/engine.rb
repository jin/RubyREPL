require 'twitter'
require 'shikashi'
require 'timeout'
require_relative 'config'

module RubyREPL
  class Engine

    attr_reader :stream_client, :rest_client
    attr_reader :sandbox, :priv

    CONFIG_STRINGS = %w(consumer_key consumer_secret access_token access_token_secret)

    METHODS = [:'+', :'-', :'*', :'/', :'%', :'**']

    def initialize
      user_config = Configuration.config
      @stream_client = Twitter::Streaming::Client.new { |config| apply_config(config, user_config) }
      @rest_client   = Twitter::REST::Client.new      { |config| apply_config(config, user_config) }

      init_sandbox
      init_privileges
      whitelist_methods METHODS
    end

    def apply_config(client_config, user_config)
      CONFIG_STRINGS.each { |str| client_config.send("#{str}=", user_config[str]) }
    end

    def init_sandbox
      @sandbox ||= Shikashi::Sandbox.new
    end

    def init_privileges
      @priv ||= Shikashi::Privileges.new
    end

    def whitelist_methods(methods)
      methods.each { |m| @priv.allow_method m }
    end

    def start_stream
      @stream_client.user(:with => "user") do |object|
        evaluate_tweet(object) if object.is_a?(Twitter::Tweet) && object.user.screen_name != 'RubyREPL'
      end
    end

    def evaluate_tweet(tweet)
      begin
        eval_output = Timeout::timeout(2) { sandboxed_eval(get_code_from_tweet(tweet)) }
        if is_valid_tweet_length("#{eval_output}#{tweet.user.screen_name}")
          reply_to_tweet(tweet, eval_output)
        else
          reply_to_tweet(tweet, "Result is too long for a tweet! // identifier: #{tweet.id}")
        end
      rescue Exception => exc
        $logger.error "#{exc}: #{tweet.text}"
        reply_to_tweet(tweet, "I'm sorry, I don't understand your input! // identifier: #{tweet.id}")
      end
    end

    def sandboxed_eval(code)
      @sandbox.run(code, @priv)
    end

    def reply_to_tweet(source, content)
      $logger.info "Reply to #{source.user.screen_name} - #{source.text} - #{content}"
      @rest_client.update("@#{source.user.screen_name} #{content}", :in_reply_to_status => source)
    end

    # utility

    def is_valid_tweet_length(str)
      str.length <= 140
    end

    def get_code_from_tweet(tweet)
      tweet.text.split(' ')[1..-1].join(' ')
    end
  end
end
