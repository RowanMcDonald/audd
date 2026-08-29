# frozen_string_literal: true

# Contract tests: drive the real client against the response fixtures captured
# in the pinned audd-openapi spec, so a change to AudD's payload shape shows up
# here rather than in production.
RSpec.describe "recognize contract", :contract do
  let(:token) { "test-token" }
  let(:audd) { Audd.new(token) }

  def stub_recognize(fixture_name)
    stub_request(:post, "https://api.audd.io/")
      .to_return(
        status: 200,
        body: JSON.generate(openapi_fixture(fixture_name)),
        headers: {"Content-Type" => "application/json"}
      )
  end

  it "is pinned to the openapi version the specs were written against" do
    expect(OpenAPI.document.dig("info", "version")).to eq(OpenAPI::PINNED_VERSION)
  end

  describe "the request we send" do
    before { stub_recognize("recognize_basic.json") }

    it "only sends multipart fields the spec documents for POST /" do
      audd.recognize(url: "https://audd.tech/example.mp3")
        .return_metadata(:apple_music, :spotify)
        .market("us")
        .execute!

      expect(OpenAPI.recognize_form_properties).to include(*sent_form_field_names)
      expect(sent_form_field_names).to include("api_token", "url", "return", "market")
    end

    it "sends an uploaded file as the `file` part and identifies itself" do
      Tempfile.create(["clip", ".mp3"]) do |clip|
        clip.write("ID3 fake audio")
        clip.flush

        audd.recognize(file: clip.path).execute!
      end

      expect(a_request(:post, "https://api.audd.io/").with { |request|
        request.headers["User-Agent"].start_with?("audd-ruby") &&
          request.headers["Content-Type"].start_with?("multipart/form-data; boundary=") &&
          request.body.include?('name="file"; filename="clip') &&
          request.body.include?("ID3 fake audio")
      }).to have_been_made
    end
  end

  describe "the response we parse" do
    it "maps a public-DB match onto RecognitionResult" do
      stub_recognize("recognize_basic.json")

      result = audd.recognize(url: "https://audd.tech/example.mp3").execute!

      expect(result).to be_a(Audd::RecognitionResult)
      expect(result.artist).to eq("Tears For Fears")
      expect(result.title).to eq("Everybody Wants To Rule The World")
      expect(result.album).to eq("Songs From The Big Chair")
      expect(result.release_date).to eq("2014-11-10")
      expect(result.timecode).to eq("00:56")
      expect(result).to be_public_match
      expect(result).not_to be_custom_match
      expect(result.thumbnail_url).to eq("https://lis.tn/NbkVb?thumb")
    end

    it "maps the metadata providers onto their own schema classes" do
      stub_recognize("recognize_with_metadata.json")

      result = audd.recognize(url: "https://audd.tech/example.mp3")
        .return_metadata(:apple_music, :spotify, :musicbrainz)
        .execute!

      expect(result.apple_music).to be_a(Audd::AppleMusicMetadata)
      expect(result.apple_music.isrc).to eq("GBUM71403885")
      expect(result.apple_music.artist_name).to eq("Tears for Fears")

      expect(result.spotify).to be_a(Audd::SpotifyMetadata)
      expect(result.spotify.duration_ms).to be_a(Integer)

      expect(result.musicbrainz).to all(be_a(Audd::MusicBrainzEntry))
      expect(result.musicbrainz.first.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it "keeps undocumented keys reachable, since the schemas allow extras" do
      stub_recognize("recognize_with_metadata.json")

      result = audd.recognize(url: "https://audd.tech/example.mp3").execute!

      # `hasLyrics` is in the live payload but not in the spec's property list.
      expect(result.apple_music["hasLyrics"]).to be(true)
    end

    it "maps a custom-catalog match, which has no public-DB fields" do
      stub_recognize("recognize_custom_match.json")

      result = audd.recognize(url: "https://audd.tech/example.mp3").execute!

      expect(result).to be_custom_match
      expect(result.audio_id).to eq(146)
      expect(result.timecode).to eq("01:45")
      expect(result.artist).to be_nil
      expect(result.thumbnail_url).to be_nil
    end

    it "returns nil when the audio was processed but nothing matched" do
      stub_request(:post, "https://api.audd.io/")
        .to_return(
          status: 200,
          body: JSON.generate({status: "success", result: nil}),
          headers: {"Content-Type" => "application/json"}
        )

      expect(audd.recognize(url: "https://audd.tech/example.mp3").execute!).to be_nil
    end
  end

  private

  def sent_form_field_names
    names = []
    WebMock::RequestRegistry.instance.requested_signatures.each do |signature, _|
      names.concat(signature.body.to_s.scan(/name="([^"]+)"/).flatten)
    end
    names.uniq
  end
end
