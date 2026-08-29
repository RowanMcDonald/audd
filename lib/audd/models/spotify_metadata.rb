# frozen_string_literal: true

require_relative "model"

module Audd
  # Mirror of the upstream Spotify track payload.
  class SpotifyMetadata < Model
    field :album
    field :artists
    field :available_markets
    field :disc_number
    field :duration_ms
    field :explicit
    field :external_ids
    field :external_urls
    field :href
    field :id
    field :is_local
    field :is_playable
    field :linked_from
    field :name
    field :popularity
    field :track_number
    field :type
    field :uri
  end
end
