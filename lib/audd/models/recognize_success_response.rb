# frozen_string_literal: true

require_relative "model"
require_relative "recognition_result"

module Audd
  # Envelope returned by POST api.audd.io/ on success. `result` is nil when the
  # audio was processed fine but nothing matched — that is a successful
  # response, not an error.
  class RecognizeSuccessResponse < Model
    field :status
    field(:result) { |v| RecognitionResult.from_json(v) }

    def match?
      !result.nil?
    end
  end
end
