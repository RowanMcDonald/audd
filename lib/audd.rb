# frozen_string_literal: true

require_relative "audd/version"
require_relative "audd/errors"

require_relative "audd/models/model"
require_relative "audd/models/apple_music_metadata"
require_relative "audd/models/deezer_metadata"
require_relative "audd/models/music_brainz_entry"
require_relative "audd/models/spotify_metadata"
require_relative "audd/models/recognition_result"
require_relative "audd/models/recognize_success_response"
require_relative "audd/models/error_response"

require_relative "audd/http_client"
require_relative "audd/response_parser"
require_relative "audd/source"
require_relative "audd/recognize_request"
require_relative "audd/client"

# Unofficial Ruby SDK for the AudD music recognition API.
#
#   audd = Audd.new("your_token")
#   result = audd.recognize(file: "clip.mp3").execute!
#   result&.title
#
# See https://docs.audd.io/ for the API itself.
module Audd
  class API
    API_BASE = "https://api.audd.io"
    ENTERPRISE_BASE = "https://enterprise.audd.io"

    def initialize(api_token)
      @api_token = api_token
    end

    def recognize(file: nil, url: nil)
      client = Client.new(api_token:, base_url: API_BASE)

      RecognizeRequest.new(client: client, file: file, url: url)
    end

    def recognize_enterprise(file: nil, url: nil)
      raise NotImplementedError
    end

    def find_lyrics(query)
      raise NotImplementedError
    end

    def inspect
      "#<#{self.class.name} api_token=[FILTERED]>"
    end

    private

    attr_reader :api_token
  end

  def self.new(api_token)
    if api_token.nil?
      raise ConfigurationError, "No AudD api_token given. Get one at https://dashboard.audd.io."
    end

    API.new(api_token)
  end
end
