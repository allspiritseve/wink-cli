require './wink/api'
require './wink/config'
require './wink/cli'

# Development convenience
require 'byebug'
require 'pp'

module Faraday
  class Response
    alias_method :to_s, :body
  end
end

module Wink
  def self.run
    Signal.trap('INT') { abort }
    CLI.new(ARGV)
  rescue Interrupt
    puts 'Quitting...'
  end
end

Wink.run
