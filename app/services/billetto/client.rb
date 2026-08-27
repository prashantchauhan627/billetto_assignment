module Billetto
  class Client
    BASE_URL = "https://billetto.dk/api/v3/"
    MAX_LIMIT = 100

    Error = Class.new(StandardError)
    ConfigurationError = Class.new(Error)
    RequestFailed = Class.new(Error)
    InvalidResponse = Class.new(Error)

    def initialize(api_key: nil, api_secret: nil)
      @api_key = api_key || Rails.application.credentials.dig(:billetto, :api_key)
      @api_secret = api_secret || Rails.application.credentials.dig(:billetto, :api_secret)

      raise ConfigurationError, "Billetto API keypair is missing" if @api_key.blank? || @api_secret.blank?
    end

    def public_events(limit: MAX_LIMIT)
      response = connection.get("public/events", limit: limit.to_i.clamp(1, MAX_LIMIT))

      raise RequestFailed, "Billetto responded with #{response.status}" unless response.success?

      extract(response.body)
    rescue Faraday::Error => e
      raise RequestFailed, "Billetto request failed: #{e.message}"
    end

    private

    def extract(body)
      body = JSON.parse(body) if body.is_a?(String)
      data = body.is_a?(Hash) ? body["data"] : nil

      raise InvalidResponse, "unexpected response shape" unless data.is_a?(Array)

      data
    rescue JSON::ParserError
      raise InvalidResponse, "Billetto returned invalid JSON"
    end

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.headers["Api-Keypair"] = "#{@api_key}:#{@api_secret}"
        f.headers["Accept"] = "application/json"
        f.options.timeout = 10
        f.options.open_timeout = 5
      end
    end
  end
end
