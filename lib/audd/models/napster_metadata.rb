# frozen_string_literal: true

require_relative "model"

module Audd
  # Mirror of the upstream Napster track payload. Absent for some tracks.
  class NapsterMetadata < Model
    field :type
    field :id
    field :index
    field :disc
    field :href
    field :playback_seconds, "playbackSeconds"
    field :explicit, "isExplicit"
    field :streamable, "isStreamable"
    field :available_in_hi_res, "isAvailableInHiRes"
    field :name
    field :isrc
    field :shortcut
    field :blurbs
    field :artist_id, "artistId"
    field :artist_name, "artistName"
    field :album_id, "albumId"
    field :album_name, "albumName"
    field :formats
    field :preview_url, "previewURL"
    field :contributors
    field :links
  end
end
