# frozen_string_literal: true

require "json"

require_relative "errors"
require_relative "models/error_response"

module Audd
  # Turns a raw HTTP response into a decoded success body, or raises the
  # matching Audd::Error subclass.
  module ResponseParser
    HTTP_CLIENT_ERROR_FLOOR = 400

    # Code 51 is a soft deprecation: the server fulfilled the request but is
    # warning about a parameter. When a result came back with it, warn and
    # carry on rather than raising.
    DEPRECATED_PARAMS_CODE = 51

    class << self
      # @return [Hash] the parsed `status: "success"` body
      def decode!(response)
        body = parse_json(response)
        return handle_deprecation(body) if deprecation_pass_through?(body)

        case body["status"]
        when "success" then body
        when "error" then raise_api_error(body, response)
        else
          raise ServerError.new(
            error_code: 0,
            error_message: "Unexpected response status: #{body["status"].inspect}",
            http_status: response.status,
            request_id: response.request_id,
            raw_response: body
          )
        end
      end

      private

      def parse_json(response)
        body = begin
          JSON.parse(response.body.to_s)
        rescue JSON::ParserError
          nil
        end
        return body if body.is_a?(Hash)

        # A non-JSON body on a failing status is the proxy or gateway talking,
        # not AudD — report it as a server error and keep the status code.
        if response.status >= HTTP_CLIENT_ERROR_FLOOR
          raise ServerError.new(
            error_code: 0,
            error_message: "HTTP #{response.status} with non-JSON response body",
            http_status: response.status,
            request_id: response.request_id,
            raw_response: response.body
          )
        end

        raise SerializationError.new(
          "Could not parse the AudD response as JSON",
          raw_body: response.body.to_s
        )
      end

      def deprecation_pass_through?(body)
        error = body["error"]
        error.is_a?(Hash) &&
          error["error_code"] == DEPRECATED_PARAMS_CODE &&
          !body["result"].nil?
      end

      def handle_deprecation(body)
        warn("[audd] #{body.dig("error", "error_message")}")
        body.except("error").merge("status" => "success")
      end

      def raise_api_error(body, response)
        envelope = ErrorResponse.new(body)
        code = Integer(envelope.error_code, exception: false) || 0

        raise Audd.error_class_for(code).new(
          error_code: code,
          error_message: envelope.error_message.to_s,
          http_status: response.status,
          request_id: response.request_id,
          request_params: envelope.request_params,
          request_method: envelope.request_api_method,
          branded_message: envelope.branded_message,
          raw_response: envelope
        )
      end
    end
  end
end
