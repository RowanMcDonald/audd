# frozen_string_literal: true

require "net/http"
require "openssl"
require "securerandom"
require "uri"

require_relative "errors"
require_relative "user_agent"

module Audd
  # Minimal multipart/form-data POST over Net::HTTP. Hand-rolled so the gem
  # ships with no runtime dependencies.
  class HttpClient
    Response = Struct.new(:status, :body, :request_id, keyword_init: true)

    # AudD only accepts multipart uploads; the field name for the upload is
    # fixed by the API.
    FILE_FIELD = "file"

    # POSTs `fields` (and optionally one file) to `url`.
    #
    # @param file [Array(String, IO), nil] a [filename, io] pair
    def post_form(url, fields:, timeout:, file: nil)
      uri = URI.parse(url)
      boundary = SecureRandom.hex(16)

      request = Net::HTTP::Post.new(uri)
      request["User-Agent"] = USER_AGENT
      request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
      request.body = multipart_body(fields, file, boundary)

      perform(uri, request, timeout)
    end

    private

    def perform(uri, request, timeout)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = timeout
      http.read_timeout = timeout
      http.write_timeout = timeout

      response = http.start { |session| session.request(request) }
      Response.new(
        status: response.code.to_i,
        body: response.body,
        request_id: response["x-request-id"]
      )
    rescue Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout => e
      raise TimeoutError, "Request to #{uri} timed out after #{timeout}s (#{e.class})"
    rescue SocketError, SystemCallError, IOError,
      OpenSSL::SSL::SSLError, Net::HTTPBadResponse, Net::ProtocolError => e
      raise ConnectionError, "Request to #{uri} failed: #{e.class}: #{e.message}"
    end

    def multipart_body(fields, file, boundary)
      body = +"".b

      fields.each do |name, value|
        body << "--#{boundary}\r\n".b
        body << "Content-Disposition: form-data; name=\"#{quote(name)}\"\r\n\r\n".b
        body << value.to_s.b
        body << "\r\n".b
      end

      if file
        filename, io = file
        body << "--#{boundary}\r\n".b
        body << "Content-Disposition: form-data; name=\"#{FILE_FIELD}\"; " \
                "filename=\"#{quote(filename)}\"\r\n".b
        body << "Content-Type: application/octet-stream\r\n\r\n".b
        body << io.read.b
        body << "\r\n".b
      end

      body << "--#{boundary}--\r\n".b
      body
    end

    # Quotes are structural in a Content-Disposition header and newlines would
    # let a filename inject headers of its own.
    def quote(value)
      value.to_s.gsub(/["\r\n]/, "_")
    end
  end
end
