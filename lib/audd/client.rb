# frozen_string_literal: true

require_relative "errors"
require_relative "http_client"
require_relative "recognize_request"

module Audd
  class Client
    attr_reader :api_token, :base_url

    def initialize(api_token:, base_url:)
      @api_token = api_token
      @base_url = base_url
      @http_client = HttpClient.new
    end

    def post(path, fields:, timeout:, file: nil)
      @http_client.post_form(
        "#{base_url}#{path}",
        fields: fields.merge("api_token" => api_token),
        timeout: timeout,
        file: file
      )
    end

    def inspect
      "#<#{self.class.name} base_url=#{base_url.inspect} api_token=[FILTERED]>"
    end
  end
end
