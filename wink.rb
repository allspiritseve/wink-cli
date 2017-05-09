require 'faraday'
require 'faraday_middleware'
require 'byebug'
require 'json'
require 'pp'
require 'launchy'

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
      unless method.to_sym == :get
        params = params.to_json
      end
      response = client.send(method, path, params, headers.merge(default_headers).merge(authorization_headers))
      log_response(method, path, params, response)
      response
    end

    def request_with_refresh(method, path, params = {}, headers = {})
      unless config.refresh_token?
        CLI.error "You don't have oauth credentials yet. Please run `configure` or `authorize` first."
      end
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

    def exchange_auth_code(auth_code)
      body = {
        client_id: config.client_id,
        client_secret: config.client_secret,
        grant_type: 'authorization_code',
        code: auth_code
      }
      response = request_oauth_credentials(body)
      CLI.error "Could not exchange authorization code" unless response.success?
    end

    def refresh_access_token
      body = {
        client_id: config.client_id,
        client_secret: config.client_secret,
        grant_type: 'refresh_token',
        refresh_token: config.refresh_token
      }
      response = request_oauth_credentials(body)
      CLI.error "Could not refresh access token" unless response.success?
    end

    def request_oauth_credentials(body = {})
      response = client.post('/oauth2/token', body.to_json, default_headers)
      if response.success?
        data = JSON.parse(response.body).fetch('data')
        config.access_token = data.fetch('access_token')
        config.refresh_token = data.fetch('refresh_token')
        config.write_file
      end
      response
    end

    def log_response(method, path, params, response)
      return unless verbose_logging?
      if method.to_sym == :get
        puts "#{response.env.method.upcase} #{response.env.url} with params #{params.to_json} returned #{response.status}"
      else
        puts "#{response.env.method.upcase} #{response.env.url} returned #{response.status}"
      end
    end

    def verbose_logging?
      false
    end
  end

  class Config < Struct.new(:config)
    extend Forwardable

    FILENAME = '.winkrc'.freeze
    KEYS = %W(base_url client_id client_secret access_token refresh_token)
    ENVIRONMENTS = %w(development test staging production)

    def initialize
      create_file
      self.config = read_file
      validate
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

  class CLI
    def self.error(message)
      puts ""
      puts message
      puts ""
      exit 1
    end

    def initialize(argv)
      command = argv[0]
      if respond_to?(command)
        puts send(command, *argv[1..-1])
      elsif respond_to?("#{command}_command")
        puts send("#{command}_command", *argv[1..-1])
      else
        error "Unknown command: #{command}"
      end
    end

    def config_command
      puts ""
      puts "Environment: #{config.environment}"
      puts "Client id: #{config.client_id}"
      puts "Client secret: #{config.client_secret}"
      puts "Access token: #{config.access_token}"
      puts "Refresh token: #{config.refresh_token}"
    end

    def configure
      puts ""
      configure_environment
      config.client_id = prompt("Enter a Wink #{config.environment} client id", config.client_id)
      config.client_secret = prompt("Enter a Wink #{config.environment} client secret", config.client_secret)
      config.write_file
      puts ""
      puts "Configuration file has been updated"
      config_command
    end

    def authorize
      url = "#{config.base_url}/oauth2/authorize?client_id=#{config.client_id}"
      Launchy.open(url)
      puts ""
      puts "Open the following URL in a browser:"
      puts ""
      puts url
      puts ""
      puts "Log in with your Wink credentials, grab the `code` parameter from the redirect URL and paste it here:"
      puts ""
      auth_code = prompt("Authorization code")
      api.exchange_auth_code(auth_code)
      credentials
    end

    def credentials
      puts ""
      puts "You have obtained Wink credentials!"
      puts ""
      puts "Refresh token: #{config.refresh_token}"
      puts "Access token: #{config.access_token}"
      puts ""
      puts "Try the `me` command to get started."
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
    def prompt(label, existing_value = nil)
      print label
      if existing_value.to_s.length > 0
        print " (#{existing_value})"
      end
      print ": "
      input = STDIN.gets.chomp
      input = existing_value if input == ''
      input
    end

    def error(message)
      self.class.error(message)
    end

    def configure_environment
      environment = prompt("Staging or production", config.environment)
      unless Config::ENVIRONMENTS.include?(environment)
        if environment = Config::ENVIRONMENTS.detect { |value| value =~ /^#{environment.downcase}/ }
          puts "Partial match, autocompleting to #{environment}"
        else
          environment = config.environment || 'staging'
          puts "Invalid value, defaulting to #{environment}"
        end
      end
      config.environment = environment
    end

    def parse_params(*args)
      if args[0] == '{' && args[-1] == '}'
        JSON.parse(args.join(' '))
      else
        args.inject({}) do |memo, arg|
          key, value = arg.split('=')
          memo.merge(key => value)
        end
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
