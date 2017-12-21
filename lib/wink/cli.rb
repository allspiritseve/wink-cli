require "wink/cli/version"

module Wink
  class CLI
    attr_accessor :argv

    def initialize(argv)
      self.argv = argv
    end

    def run
      puts 'Hola!'
    end
  end
end
