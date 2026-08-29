# frozen_string_literal: true

require_relative "audd/version"
require_relative "audd/user_agent"
require_relative "audd/errors"
require_relative "audd/models/model"
require_relative "audd/models/apple_music_metadata"
require_relative "audd/models/deezer_metadata"
require_relative "audd/models/music_brainz_entry"
require_relative "audd/models/napster_metadata"
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
  # Convenience so callers write Audd.new(token) rather than Audd::Client.new.
  def self.new(api_token = nil, **options)
    Client.new(api_token, **options)
  end
end
