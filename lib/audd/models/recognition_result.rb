# frozen_string_literal: true

require "uri"

require_relative "model"
require_relative "apple_music_metadata"
require_relative "deezer_metadata"
require_relative "music_brainz_entry"
require_relative "spotify_metadata"

module Audd
  # A single recognition result. Which fields are populated depends on which
  # catalog matched:
  #
  # * public-DB match — +artist+, +title+, +album+, +release_date+, +label+
  #   and +song_link+ are populated and +audio_id+ is absent;
  # * custom-DB match (your own fingerprint catalog) — only +timecode+ and
  #   +audio_id+ are populated.
  #
  # Use #public_match? / #custom_match? rather than testing +artist+ for nil.
  class RecognitionResult < Model
    # Only lis.tn-hosted song links serve cover art from `?thumb`.
    THUMBNAIL_HOST = "lis.tn"

    # Position in the recognized song (MM:SS) at which the matched fragment plays.
    field :timecode
    field :audio_id
    field :artist
    field :title
    field :album
    field :release_date
    field :label
    field :song_link
    field(:apple_music) { |v| AppleMusicMetadata.from_json(v) }
    field(:spotify) { |v| SpotifyMetadata.from_json(v) }
    field(:deezer) { |v| DeezerMetadata.from_json(v) }
    field(:musicbrainz) { |v| Array(v).filter_map { |e| MusicBrainzEntry.from_json(e) } }

    # Matched against your own fingerprint catalog rather than the public DB.
    def custom_match?
      !audio_id.nil?
    end

    def public_match?
      audio_id.nil?
    end

    # Cover art for the match, or nil when there's no song_link to build it
    # from — appending ?thumb only means anything on lis.tn.
    def thumbnail_url
      return nil if song_link.nil?
      return nil unless URI.parse(song_link).host == THUMBNAIL_HOST

      "#{song_link}?thumb"
    rescue URI::InvalidURIError
      nil
    end
  end
end
