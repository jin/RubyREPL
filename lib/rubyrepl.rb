require_relative 'engine'
require 'logger'

$logger = Logger.new('rubyrepl.log', 20, 'daily')
RubyREPL::Engine.new.start_stream
