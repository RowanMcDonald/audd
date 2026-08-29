# frozen_string_literal: true

require_relative "errors"
require_relative "models/recognize_success_response"
require_relative "response_parser"
require_relative "source"

module Audd
  # Chainable builder for POST api.audd.io/. Built by Audd::Client#recognize;
  # nothing is sent until #execute!.
  #
  #   audd.recognize(file: "clip.mp3")
  #       .return_metadata(:apple_music, :spotify)
  #       .market("us")
  #       .execute!
  class RecognizeRequest
    RETURN_METADATA_SOURCES = %w[apple_music spotify deezer musicbrainz].freeze

    # The server holds the connection open while it fingerprints the audio,
    # so this is generous by HTTP standards.
    DEFAULT_TIMEOUT = 60

    attr_reader :file, :url

    def initialize(client:, file: nil, url: nil, timeout: DEFAULT_TIMEOUT)
      if file.nil? == url.nil?
        raise InvalidParameterError,
          "recognize requires exactly one of file: or url:, got " \
          "#{file.nil? ? "neither" : "both"}."
      end

      @client = client
      @file = file
      @url = url
      @timeout = timeout
      @return_metadata = []
      @market = nil
    end

    # Extra metadata to fetch for the match, e.g. :apple_music, :spotify.
    # Repeated calls accumulate.
    def return_metadata(*sources)
      sources = sources.flatten.map(&:to_s)
      unknown = sources - RETURN_METADATA_SOURCES

      unless unknown.empty?
        raise InvalidParameterError,
          "unknown return_metadata source(s): #{unknown.join(", ")}. " \
          "Valid sources: #{RETURN_METADATA_SOURCES.join(", ")}."
      end

      @return_metadata |= sources
      self
    end

    # ISO country code for the regional Apple Music / Spotify catalogs.
    def market(code)
      @market = code.to_s
      self
    end

    # Overrides DEFAULT_TIMEOUT for this request, in seconds.
    def timeout(seconds)
      @timeout = seconds
      self
    end

    # Sends the request.
    #
    # @return [Audd::RecognitionResult, nil] nil when the audio was processed
    #   but nothing matched — a successful response, not an error.
    def execute!
      body = Source.with_file(@file) do |file_part|
        response = @client.post("/", fields: form_fields, timeout: @timeout, file: file_part)
        ResponseParser.decode!(response)
      end

      RecognizeSuccessResponse.new(body).result
    end

    # The multipart fields this request will send, minus the api_token the
    # client adds.
    def form_fields
      fields = {}
      fields["url"] = @url if @url
      fields["return"] = @return_metadata.join(",") unless @return_metadata.empty?
      fields["market"] = @market if @market
      fields
    end
  end
end
