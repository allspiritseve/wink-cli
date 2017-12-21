require 'launchy'
require 'json'
require 'rack'

module Wink
  class CLI
    VERSION = '0.1.7'

    def self.error(message)
      puts ""
      puts message
      puts ""
      exit 1
    end

    def initialize(argv)
      case argv[0]
      when '--staging'
        config.environment = 'staging'
        argv.shift
      when '--production'
        config.environment = 'production'
        argv.shift
      end
      command = argv[0]

      if !command
        puts "Hola!"
      elsif respond_to?(command)
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

    def access_token_command
      me
      print config.access_token
    end

    def configure
      config(validate: false)
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
      config(validate: false)
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
        Rack::Utils.parse_nested_query(args.join('&'))
      end
    end

    def api
      @api ||= API.new(config)
    end

    def config(validate: true)
      @config ||= Config.new(validate: validate)
    end
  end
end
