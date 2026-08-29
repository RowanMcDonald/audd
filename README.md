# Audd

Unofficial ruby sdk for AudD music recognition api. https://docs.audd.io/

I've only implemented the parts of the api that I use, please open prs to contribute any additional functionality you would like.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add audd
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install audd
```

## Usage


### Recognize a song
```ruby
api_token = "your_token"
audd = Audd.new(api_token)

# read https://docs.audd.io/#recognize to learn about request options.
request = audd.recognize(file: file) # one of file: file or url: url
    .return_metadata(:apple_music, :musicbrainz, :spotify, :deezer)
    .market("us")

result = request.execute!
```

`file:` takes a path, a `Pathname`, or an open `IO`; `url:` takes an https url that
AudD downloads itself. Pass exactly one of them.

Nothing is sent until `execute!`, which returns an `Audd::RecognitionResult` — or
`nil` when the audio was processed fine but didn't match anything. That is a
successful response, not an error.

```ruby
result.title        #=> "Everybody Wants To Rule The World"
result.artist       #=> "Tears For Fears"
result.timecode     #=> "00:56" — where in the song the matched fragment plays
result.apple_music  #=> Audd::AppleMusicMetadata
result.public_match? #=> true (false for matches against your own catalog)
```

The response classes are plain objects named after the [AudD OpenAPI
schemas](https://github.com/AudDMusic/audd-openapi), namespaced under `Audd`:
`RecognitionResult`, `AppleMusicMetadata`, `SpotifyMetadata`, `DeezerMetadata`,
`NapsterMetadata` and `MusicBrainzEntry`. Those schemas all allow extra
properties and AudD passes provider payloads through verbatim, so any key the
gem doesn't map is still reachable — `result.apple_music["hasLyrics"]` — and the
whole payload is on `#raw`.

Only `recognize` is implemented. `Audd::Client#recognize_enterprise` and
`Audd::Client#find_lyrics` raise `NotImplementedError`.

### Timeouts
Because the recognize endpoint holds a long request open, the timeout for that endpoint is 60 seconds
 - make sure not to make this request inside of an http transaction.

Override it per request with `.timeout(seconds)`. On expiry you get an
`Audd::TimeoutError`. Note that AudD meters the request server-side whether or
not you wait for the answer.

### Errors

Everything raised descends from `Audd::Error`, so one `rescue` catches the lot:

```
Audd::Error
├── Audd::ConfigurationError     # no api_token given and AUDD_API_TOKEN unset
├── Audd::InvalidParameterError  # bad arguments — raised before anything is sent
├── Audd::ConnectionError        # network, DNS, or TLS failure; nothing was received
│   └── Audd::TimeoutError       # the request outran its timeout
├── Audd::SerializationError     # a 2xx response whose body wasn't parseable JSON
└── Audd::ApiError               # the server answered status: "error"
    ├── Audd::AuthenticationError
    ├── Audd::QuotaError
    ├── Audd::SubscriptionError
    ├── Audd::InvalidRequestError
    ├── Audd::InvalidAudioError
    ├── Audd::StreamLimitError
    ├── Audd::RateLimitError
    ├── Audd::NotReleasedError
    ├── Audd::BlockedError
    ├── Audd::NeedsUpdateError
    └── Audd::ServerError
```

`Audd::ConfigurationError` and `Audd::InvalidParameterError` are raised locally,
before any HTTP happens — a missing token, neither or both of `file:`/`url:`, an
unreadable path, or a `return_metadata` source AudD doesn't accept.

The rest of the hierarchy comes from the server. Each AudD error code maps to
one class:

| Code(s) | Class | Meaning |
|---|---|---|
| 900, 901, 903 | `Audd::AuthenticationError` | The api_token is missing, wrong, or inactive |
| 902 | `Audd::QuotaError` | Quota or per-copy limit reached |
| 904, 905 | `Audd::SubscriptionError` | The endpoint isn't available on this plan |
| 50, 51, 600, 601, 602, 700, 701, 702, 906 | `Audd::InvalidRequestError` | Bad input — no file or url sent, malformed parameters |
| 300, 400, 500 | `Audd::InvalidAudioError` | The audio itself couldn't be read or fingerprinted |
| 610 | `Audd::StreamLimitError` | Subscription stream slots exhausted |
| 611 | `Audd::RateLimitError` | Per-stream daily rate limit |
| 907 | `Audd::NotReleasedError` | The song hasn't been released yet |
| 19, 31337 | `Audd::BlockedError` | Security, abuse, sanctions, IP ban, or maintenance |
| 20 | `Audd::NeedsUpdateError` | Client needs updating / paid version required |
| 100, 1000, anything else | `Audd::ServerError` | Upstream failure, and every code this gem doesn't recognise |

Code 51 is the exception to the rule: it's a soft deprecation warning. When the
server sends it *and* still returns a result, the gem warns on stderr and hands
you the result instead of raising.

Every `Audd::ApiError` carries `error_code`, `error_message`, `http_status`,
`request_id`, `request_params`, `request_method`, `branded_message` and
`raw_response` — enough to log an incident or open a ticket with AudD support.

```ruby
begin
  result = audd.recognize(file: file).execute!
rescue Audd::AuthenticationError => e
  abort "check your token: #{e.message}"
rescue Audd::InvalidAudioError => e
  warn "we sent something unusable: #{e.error_message}"
rescue Audd::ApiError => e
  warn "AudD ##{e.error_code}: #{e.error_message} (request_id=#{e.request_id})"
end
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Testing
We use contract testing based on the audd openapi https://github.com/AudDMusic/audd-openapi library.

It's vendored as a git submodule at `spec/audd-openapi`, pinned to a tag (`v1.4.4`)
so the contract can't move under us without a reviewable diff. Fetch it with:

```bash
git submodule update --init
```

The contract specs read both the spec document — to check we only send the form
fields `POST /` documents, and that every error code it enumerates maps to an
exception class — and the captured response fixtures, which they replay through
the real client. Without the submodule those specs skip rather than fail, so the
rest of the suite still runs on a fresh clone.

To take a new spec version: update the submodule to the new tag, bump
`OpenAPI::PINNED_VERSION` in `spec/support/openapi.rb`, and run `rake`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/RowanMcDonald /audd. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/audd/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Audd project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/audd/blob/main/CODE_OF_CONDUCT.md).
