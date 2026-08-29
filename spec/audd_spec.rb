# frozen_string_literal: true

RSpec.describe Audd do
  it "has a version number" do
    expect(Audd::VERSION).not_to be nil
  end

  xit "raises error when the api errors" do
    # TODO: setup error mock
    #
    expect {
      Audd.new("test").recognize_enterprise(file: file).execute!
    }.to raise_error Audd::Error
  end
end
