# frozen_string_literal: true

module Audd
  # Base of everything this gem raises. `rescue Audd::Error` catches the lot.
  class Error < StandardError; end

  # Raised before any request is made.

  # No api_token was supplied and AUDD_API_TOKEN is unset.
  class ConfigurationError < Error; end

  # The caller passed something the API can't accept: neither (or both) of
  # `file:`/`url:`, an unknown `return` source, an unreadable file.
  class InvalidParameterError < Error; end

  # Raised when no usable response came back.

  # Network, DNS, or TLS failure — nothing was received.
  class ConnectionError < Error; end

  # The request outran its timeout. Recognition holds the connection open
  # while the server fingerprints the audio, so this is the one to watch.
  class TimeoutError < ConnectionError; end

  # A 2xx response whose body wasn't parseable JSON.
  class SerializationError < Error
    attr_reader :raw_body

    def initialize(message, raw_body: "")
      @raw_body = raw_body
      super(message)
    end
  end

  # The server answered with `status: "error"`. Carries the AudD error code
  # plus the server's full echo of the request, which is what AudD support
  # asks for.
  class ApiError < Error
    attr_reader :error_code, :error_message, :http_status, :request_id,
      :request_params, :request_method, :branded_message, :raw_response

    def initialize(error_code:, error_message:, http_status: nil, request_id: nil,
      request_params: {}, request_method: nil, branded_message: nil, raw_response: nil)
      @error_code = error_code
      @error_message = error_message
      @http_status = http_status
      @request_id = request_id
      @request_params = request_params || {}
      @request_method = request_method
      @branded_message = branded_message
      @raw_response = raw_response
      super("[##{error_code}] #{error_message}")
    end
  end

  # 900 / 901 / 903 — the token is the problem.
  class AuthenticationError < ApiError; end

  # 902 — quota or per-copy limit reached.
  class QuotaError < ApiError; end

  # 904 / 905 — the endpoint isn't available on this plan.
  class SubscriptionError < ApiError; end

  # 50 / 51 / 600 / 601 / 602 / 700 / 701 / 702 / 906 — bad input from the caller.
  class InvalidRequestError < ApiError; end

  # 300 / 400 / 500 — the audio itself is the problem.
  class InvalidAudioError < ApiError; end

  # 610 — subscription stream slots exhausted.
  class StreamLimitError < ApiError; end

  # 611 — per-stream daily rate limit.
  class RateLimitError < ApiError; end

  # 907 — the song hasn't been released yet.
  class NotReleasedError < ApiError; end

  # 19 / 31337 — security, abuse, sanctions, IP ban, or maintenance.
  class BlockedError < ApiError; end

  # 20 — the client needs updating / a paid version is required.
  class NeedsUpdateError < ApiError; end

  # 100 / 1000, and every code this gem doesn't recognise.
  class ServerError < ApiError; end

  # Maps AudD's numeric error codes onto the classes above. The code list is
  # the enum in the OpenAPI `ErrorResponse` schema; 40 has no documented
  # meaning, so it falls through to ServerError along with anything new.
  ERROR_CLASSES_BY_CODE = {
    900 => AuthenticationError,
    901 => AuthenticationError,
    903 => AuthenticationError,
    902 => QuotaError,
    904 => SubscriptionError,
    905 => SubscriptionError,
    50 => InvalidRequestError,
    51 => InvalidRequestError,
    600 => InvalidRequestError,
    601 => InvalidRequestError,
    602 => InvalidRequestError,
    700 => InvalidRequestError,
    701 => InvalidRequestError,
    702 => InvalidRequestError,
    906 => InvalidRequestError,
    300 => InvalidAudioError,
    400 => InvalidAudioError,
    500 => InvalidAudioError,
    610 => StreamLimitError,
    611 => RateLimitError,
    907 => NotReleasedError,
    19 => BlockedError,
    31337 => BlockedError,
    20 => NeedsUpdateError,
    100 => ServerError,
    1000 => ServerError
  }.freeze

  # Unknown codes are still errors — just not ones we can name.
  def self.error_class_for(code)
    ERROR_CLASSES_BY_CODE.fetch(code, ServerError)
  end
end
