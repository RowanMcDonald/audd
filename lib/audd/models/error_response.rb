# frozen_string_literal: true

require_relative "model"

module Audd
  # Envelope returned with `status: "error"`. ResponseParser turns one of these
  # into the matching Audd::ApiError subclass; it is exposed because the
  # exception hands the parsed envelope back on #raw_response.
  class ErrorResponse < Model
    field :status
    field :error
    # The standard endpoint names this `request_params`; the enterprise
    # endpoint names the same thing `requested_params`. Normalized in #initialize.
    field :request_params
    field :request_api_method
    field :request_http_method
    field :execution_time
    field :result

    def initialize(raw)
      super
      @request_params ||= raw["requested_params"]
    end

    def error_code
      dig_error("error_code")
    end

    def error_message
      dig_error("error_message")
    end

    # Codes 19 and 31337 may carry a "branded" artist/title instead of a real
    # result. It is deliberately not surfaced as a recognition result.
    def branded_message
      return nil unless result.is_a?(Hash)

      parts = [result["artist"], result["title"]].compact.map(&:to_s).reject(&:empty?)
      parts.empty? ? nil : parts.join(" — ")
    end

    private

    # `error` is documented as an object, but a bare string shows up in the
    # wild; surface it as the message rather than blowing up on #[].
    def dig_error(key)
      case error
      when Hash then error[key]
      when String then (key == "error_message") ? error : nil
      end
    end
  end
end
