# frozen_string_literal: true

require_relative "model"

module Audd
  # Mirror of the upstream Apple Music track payload, passed through verbatim
  # by AudD. Field names stay camelCase to match the JSON keys.
  class AppleMusicMetadata < Model
    field :previews
    field :artwork
    field :artist_name, "artistName"
    field :url
    field :disc_number, "discNumber"
    field :genre_names, "genreNames"
    field :duration_in_millis, "durationInMillis"
    field :release_date, "releaseDate"
    field :name
    field :isrc
    field :album_name, "albumName"
    field :play_params, "playParams"
    field :track_number, "trackNumber"
    field :composer_name, "composerName"
  end
end
