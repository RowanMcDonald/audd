# frozen_string_literal: true

require_relative "model"

module Audd
  # A single MusicBrainz recording match. AudD returns an array of these,
  # because MusicBrainz matching often surfaces several candidates.
  class MusicBrainzEntry < Model
    field :id
    # MusicBrainz sometimes returns score as a string, sometimes as an integer.
    field :score
    field :title
    field :length
    field :disambiguation
    field :video
    field :artist_credit, "artist-credit"
    field :releases
    field :isrcs
    field :tags
  end
end
