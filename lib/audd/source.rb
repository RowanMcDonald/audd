# frozen_string_literal: true

require "pathname"

require_relative "errors"

module Audd
  # Normalizes whatever the caller passed as `file:` into the [filename, io]
  # pair HttpClient wants.
  module Source
    FALLBACK_FILENAME = "upload.bin"

    # Yields [filename, io], closing only handles we opened ourselves — a
    # caller-supplied IO stays the caller's to manage.
    def self.with_file(file)
      return yield(nil) if file.nil?

      if file.respond_to?(:read)
        name = file.respond_to?(:path) ? File.basename(file.path) : FALLBACK_FILENAME
        yield [name, file]
      else
        path = Pathname.new(file.to_s)
        unless path.file?
          raise InvalidParameterError,
            "file: #{file.inspect} is not a readable file. Pass a path, a " \
            "Pathname, or an open IO — or use url: to have AudD fetch it."
        end
        path.open("rb") { |io| yield [path.basename.to_s, io] }
      end
    end
  end
end
