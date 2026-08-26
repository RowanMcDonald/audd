# frozen_string_literal: true

RSpec.describe Audd do
  it "has a version number" do
    expect(Audd::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(Audd.new("test").).to eq(true)
  end
end
