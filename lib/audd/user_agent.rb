# frozen_string_literal: true

require_relative "version"

module Audd
  # Sent on every request, e.g. "audd-ruby/0.1.0 ruby/3.4.9 (arm64-darwin25)".
  # AudD support asks for this string when diagnosing an account's traffic.
  USER_AGENT = "audd-ruby/#{VERSION} ruby/#{RUBY_VERSION} (#{RUBY_PLATFORM})"
end
