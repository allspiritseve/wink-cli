require 'faraday'
require 'faraday_middleware'

module Wink
  class API < Struct.new(:config)
    def client
      @client ||= Faraday.new(config.base_url) do |faraday|
        faraday.ssl[:version] = :TLSv1
        faraday.response :json, content_type: /\bjson%/
        faraday.use FaradayMiddleware::FollowRedirects
        faraday.adapter(Faraday.default_adapter)
        faraday.headers[:user_agent] = "api/2.0.0 wink-cli/#{CLI::VERSION}"
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
end
