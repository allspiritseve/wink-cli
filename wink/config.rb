require 'fileutils'

module Wink
  class Config < Struct.new(:config)
    extend Forwardable

    FILENAME = '.winkrc'.freeze
    KEYS = %W(base_url client_id client_secret access_token refresh_token)
    ENVIRONMENTS = %w(development test staging production)

    def initialize(validate: true)
      create_file
      self.config = read_file
      self.validate if validate
      write_file
    end

    def environment
      config.fetch('current_environment', 'staging')
    end

    def environment=(environment)
      config.store('current_environment', environment)
    end

    def current
      config.fetch(environment)
    end

    KEYS.each do |key|
      define_method(key) do
        current.fetch(key)
      end

      define_method("#{key}=") do |value|
        current.store(key, value)
      end

      define_method("#{key}?") do
        current.fetch(key).to_s.length > 0
      end
    end

    def update(attributes = {})
      attributes.each do |key, value|
        send("#{key}=", value)
      end
      write_file
    end

    def validate
      unless base_url? && client_id? && client_secret?
        CLI.error "Please run `configure`"
      end
      unless access_token? && refresh_token?
        CLI.error "Please run `configure` or `authorize`"
      end
    end

    def create_file
      FileUtils.cp('.winkrc.sample', FILENAME) unless File.exist?(FILENAME)
    end

    def read_file
      JSON.parse(File.read(FILENAME))
    end

    def write_file
      File.write(FILENAME, JSON.pretty_generate(config))
    end
  end
end
