require 'yaml'

module RubyREPL
  module Configuration
    class << self

      attr_accessor :config 

      def config
        @config = YAML::load_file "../user_config.yml" unless @config
        @config
      end

    end
  end
end
