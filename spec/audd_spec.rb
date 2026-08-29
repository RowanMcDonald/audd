# frozen_string_literal: true

RSpec.describe Audd do
  it "has a version number" do
    expect(Audd::VERSION).not_to be nil
  end

  it "identifies itself with a project-specific user agent" do
    expect(Audd::USER_AGENT).to start_with("audd-ruby/#{Audd::VERSION} ")
  end

  describe ".new" do
    it "builds a client" do
      expect(Audd.new("token")).to be_a(Audd::Client)
    end

    it "falls back to AUDD_API_TOKEN" do
      allow(ENV).to receive(:[]).with("AUDD_API_TOKEN").and_return("from-env")

      expect(Audd.new.api_token).to eq("from-env")
    end

    it "raises rather than letting the server reject an empty token" do
      allow(ENV).to receive(:[]).with("AUDD_API_TOKEN").and_return(nil)

      expect { Audd.new }.to raise_error(Audd::ConfigurationError, /dashboard.audd.io/)
    end

    it "keeps the token out of #inspect" do
      expect(Audd.new("s3cret").inspect).not_to include("s3cret")
    end
  end

  describe "#recognize" do
    let(:audd) { Audd.new("token") }

    it "requires exactly one of file: or url:" do
      expect { audd.recognize }
        .to raise_error(Audd::InvalidParameterError, /got neither/)
      expect { audd.recognize(file: "a.mp3", url: "https://example.com/a.mp3") }
        .to raise_error(Audd::InvalidParameterError, /got both/)
    end

    it "rejects metadata sources the API doesn't accept" do
      expect { audd.recognize(url: "https://example.com/a.mp3").return_metadata(:tidal) }
        .to raise_error(Audd::InvalidParameterError, /tidal/)
    end

    it "rejects a file path that isn't readable before making a request" do
      expect { audd.recognize(file: "/nope/missing.mp3").execute! }
        .to raise_error(Audd::InvalidParameterError, /not a readable file/)
    end

    it "chains, and defaults the timeout to 60 seconds" do
      request = audd.recognize(url: "https://example.com/a.mp3")

      expect(request.return_metadata(:spotify).market("gb")).to be(request)
      expect(request.form_fields)
        .to eq("url" => "https://example.com/a.mp3", "return" => "spotify", "market" => "gb")
      expect(Audd::RecognizeRequest::DEFAULT_TIMEOUT).to eq(60)
    end
  end
end
