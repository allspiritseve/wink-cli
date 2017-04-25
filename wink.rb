require 'faraday'
require 'faraday_middleware'
require 'byebug'
require 'json'
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

  class API < Struct.new(:config)
    def client
      @client ||= Faraday.new(config.base_url) do |faraday|
        faraday.ssl[:version] = :TLSv1
        faraday.response :json, content_type: /\bjson%/
        faraday.use FaradayMiddleware::FollowRedirects
        faraday.adapter(Faraday.default_adapter)
      end
    end

    def default_headers
      {
        'Content-Type' => 'application/json'
      }
    end

    def authorization_headers
      {
        'Authorization' => "Bearer #{config.access_token}"
      }
    end

    def request(method, path, params = {}, headers = {})
      response = client.send(method, path, params.to_json, headers.merge(default_headers).merge(authorization_headers))
      log_response(method, path, params, response)
      response
    end

    def request_with_refresh(method, path, params = {}, headers = {})
      response = request(method, path, params, headers)
      if response.status == 401
        refresh_access_token
        response = request(method, path, params, headers)
      end
      response
    end

    %w(get post put patch delete).each do |method|
      define_method(method) do |*args|
        request(method, *args)
      end

      define_method("#{method}_with_refresh") do |*args|
        request_with_refresh(method, *args)
      end
    end

    def refresh_access_token
      body = {
        client_id: config.client_id,
        client_secret: config.client_secret,
        grant_type: 'refresh_token',
        refresh_token: config.refresh_token
      }
      response = client.post('/oauth2/token', body.to_json, default_headers)
      if response.success?
        data = JSON.parse(response.body).fetch('data')
        config.access_token = data['access_token']
        config.refresh_token = data['refresh_token']
        config.write_file
      else
        raise "Could not refresh access token"
      end
    end

    def log_response(method, path, params, response)
      if method.to_sym == :get
        puts "#{response.env.method.upcase} #{response.env.url} with params #{params.to_json} returned #{response.status}"
      else
        puts "#{response.env.method.upcase} #{response.env.url} returned #{response.status}"
      end
    end
  end

  class Config < Struct.new(:config)
    extend Forwardable

    FILENAME = '.winkrc'.freeze
    KEYS = %W(base_url client_id client_secret access_token refresh_token)

    def initialize
      self.config = read_file
      validate
      write_file
    end

    def environment
      config.fetch('current_environment')
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
    end

    def validate
      unless base_url && client_id && client_secret && access_token && refresh_token
        puts "Please fill out .winkrc with config values"
        exit 1
      end
    end

    def read_file
      FileUtils.cp('.winkrc.sample', FILENAME) unless File.exist?(FILENAME)
      JSON.parse(File.read(FILENAME))
    end

    def write_file
      File.write(FILENAME, JSON.pretty_generate(config))
    end
  end

  class CLI
    def initialize(argv)
      command = argv[0]
      if respond_to?(command)
        puts send(command, *argv[1..-1])
      else
        raise "Unknown command: #{command}"
      end
    end

    def me
      api.get_with_refresh('/users/me')
    end

    def get(path, *args)
      api.get_with_refresh(path, parse_params(*args))
    end

    def post(path, *args)
      api.post_with_refresh(path, parse_params(*args))
    end

    def put(path, *args)
      api.put_with_refresh(path, parse_params(*args))
    end

    def patch(path, *args)
      api.patch_with_refresh(path, parse_params(*args))
    end

    def delete(path, *args)
      api.delete_with_refresh(path, parse_params(*args))
    end

    private
    def parse_params(*args)
      args.inject({}) do |memo, arg|
        key, value = arg.split('=')
        memo.merge(key => value)
      end
    end

    def api
      @api ||= API.new(config)
    end

    def config
      @config ||= Config.new
    end
  end
end

Wink.run
