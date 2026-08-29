# frozen_string_literal: true

require_relative "errors"
require_relative "http_client"
require_relative "recognize_request"

module Audd
  # Entry point for the AudD API. Build one with Audd.new(api_token).
  class Client
    API_BASE = "https://api.audd.io"
    ENTERPRISE_BASE = "https://enterprise.audd.io"

    # Consulted when no api_token is passed explicitly.
    TOKEN_ENV_VAR = "AUDD_API_TOKEN"

    attr_reader :api_token, :base_url

    def initialize(api_token = nil, base_url: API_BASE)
      @api_token = resolve_token(api_token)
      @base_url = base_url
      @http_client = HttpClient.new
    end

    # Identifies a song from a short clip (up to 25 seconds, 10 MB). Returns a
    # builder; call #execute! to send it.
    #
    #   audd.recognize(url: "https://example.com/clip.mp3").execute!
    #
    # @param file [String, Pathname, IO, nil] audio to upload
    # @param url [String, nil] audio for AudD to fetch; pass one or the other
    # @return [Audd::RecognizeRequest]
    def recognize(file: nil, url: nil)
      RecognizeRequest.new(client: self, file: file, url: url)
    end

    def recognize_enterprise(file: nil, url: nil)
      raise NotImplementedError
    end

    def find_lyrics(query)
      raise NotImplementedError
    end

    # Sends a multipart POST with the api_token attached. Used by the request
    # builders; not part of the public API.
    def post(path, fields:, timeout:, file: nil)
      @http_client.post_form(
        "#{base_url}#{path}",
        fields: fields.merge("api_token" => api_token),
        timeout: timeout,
        file: file
      )
    end

    def inspect
      "#<#{self.class.name} base_url=#{base_url.inspect} api_token=[FILTERED]>"
    end

    private

    def resolve_token(api_token)
      token = api_token || ENV[TOKEN_ENV_VAR]

      if token.nil? || token.to_s.empty?
        raise ConfigurationError,
          "No AudD api_token given and #{TOKEN_ENV_VAR} is unset. Get one at " \
          "https://dashboard.audd.io and pass it as Audd.new(token)."
      end
      token
    end
  end
end
