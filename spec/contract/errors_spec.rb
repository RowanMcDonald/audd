# frozen_string_literal: true

# Contract tests for the error envelope: every captured error fixture must
# arrive as the right typed exception, carrying the fields support asks for.
RSpec.describe "error contract", :contract do
  let(:audd) { Audd.new("test-token") }

  def stub_error(fixture_name)
    stub_request(:post, "https://api.audd.io/")
      .to_return(
        status: 200,
        body: JSON.generate(openapi_fixture(fixture_name)),
        headers: {"Content-Type" => "application/json"}
      )
  end

  def recognize!
    audd.recognize(url: "https://audd.tech/example.mp3").execute!
  end

  it "raises AuthenticationError for a rejected api_token (900)" do
    stub_error("error_900_invalid_token.json")

    expect { recognize! }.to raise_error(Audd::AuthenticationError) do |error|
      expect(error.error_code).to eq(900)
      expect(error.error_message).to include("the provided api_token is incorrect")
      expect(error.message).to start_with("[#900]")
      expect(error.http_status).to eq(200)
      expect(error.request_method).to eq("recognize")
      # The server redacts the token in its echo; we pass it through as-is.
      expect(error.request_params["api_token"]).to eq("d***a")
    end
  end

  it "raises InvalidRequestError when no audio was sent (700)" do
    stub_error("error_700_no_file.json")

    expect { recognize! }.to raise_error(Audd::InvalidRequestError) do |error|
      expect(error.error_code).to eq(700)
    end
  end

  it "normalizes the enterprise endpoint's `requested_params` spelling (904)" do
    stub_error("error_904_enterprise_unauthorized.json")

    expect { recognize! }.to raise_error(Audd::SubscriptionError) do |error|
      expect(error.error_code).to eq(904)
      expect(error.request_params["url"]).to eq("https://audd.tech/example.mp3")
    end
  end

  it "maps every error code the spec enumerates to an ApiError subclass" do
    codes = OpenAPI.document.dig(
      "components", "schemas", "ErrorResponse",
      "properties", "error", "properties", "error_code", "enum"
    )

    expect(codes).not_to be_empty
    codes.each do |code|
      expect(Audd.error_class_for(code)).to be < Audd::ApiError
    end
  end

  it "surfaces a non-JSON gateway response as a ServerError, not a parse crash" do
    stub_request(:post, "https://api.audd.io/")
      .to_return(status: 502, body: "<html>Bad Gateway</html>")

    expect { recognize! }.to raise_error(Audd::ServerError, /HTTP 502/)
  end

  it "raises TimeoutError when the recognition request outruns its timeout" do
    stub_request(:post, "https://api.audd.io/").to_timeout

    expect { recognize! }.to raise_error(Audd::TimeoutError)
  end
end
