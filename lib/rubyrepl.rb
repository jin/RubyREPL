require_relative 'engine'
$logger = Logger.new('rubyrepl.log', 20, 'daily')

RubyREPL::Engine.new.start_stream
