# frozen_string_literal: true

require "json"
require "pathname"
require "yaml"

# Access to the pinned audd-openapi contract: the spec document itself and the
# captured response fixtures every official AudD SDK validates against.
#
# The spec lives in the spec/audd-openapi git submodule, pinned to a tag. Run
# `git submodule update --init` to fetch it; without it the contract specs skip
# rather than fail, so a fresh clone can still run the unit specs.
module OpenAPI
  ROOT = Pathname.new(__dir__).join("..", "audd-openapi").expand_path
  DOCUMENT_PATH = ROOT.join("openapi.yaml")
  FIXTURES_PATH = ROOT.join("fixtures")

  # The pinned tag. Bump deliberately, alongside the submodule pointer, so a
  # contract change is always a reviewable diff.
  PINNED_VERSION = "1.4.4"

  class << self
    def available?
      DOCUMENT_PATH.file?
    end

    def document
      @document ||= YAML.safe_load_file(DOCUMENT_PATH, aliases: true)
    end

    def fixture(name)
      JSON.parse(FIXTURES_PATH.join(name).read)
    end

    # The multipart field names POST / documents, per the pinned spec.
    def recognize_form_properties
      document
        .dig("paths", "/", "post", "requestBody", "content", "multipart/form-data", "schema", "properties")
        .keys
    end
  end

  module Helpers
    def openapi_fixture(name)
      OpenAPI.fixture(name)
    end
  end
end

RSpec.configure do |config|
  config.before(:each, :contract) do
    unless OpenAPI.available?
      skip "audd-openapi submodule not checked out — run `git submodule update --init`"
    end
  end
end
