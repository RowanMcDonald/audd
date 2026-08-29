# frozen_string_literal: true

require_relative "model"

module Audd
  # Mirror of the upstream Deezer track payload. Absent for some tracks.
  class DeezerMetadata < Model
    field :id
    field :readable
    field :title
    field :title_short
    field :title_version
    field :link
    field :duration
    field :rank
    field :explicit_lyrics
    field :explicit_content_lyrics
    field :explicit_content_cover
    field :preview
    field :md5_image
    field :artist
    field :album
    field :type
  end
end
