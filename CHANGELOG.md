## [Unreleased]

### Added

- `Audd::Client#recognize` — the `POST api.audd.io/` recognition endpoint, via a
  chainable request builder (`.return_metadata`, `.market`, `.timeout`) that sends
  on `#execute!`. Takes a file path, `Pathname`, or `IO` as `file:`, or an https
  url as `url:`.
- Response objects named after the AudD OpenAPI schemas and namespaced under
  `Audd`: `RecognitionResult`, `RecognizeSuccessResponse`, `ErrorResponse`,
  `AppleMusicMetadata`, `SpotifyMetadata`, `DeezerMetadata`, `NapsterMetadata`
  and `MusicBrainzEntry`. Unmapped keys stay reachable via `#[]` and `#raw`.
- An exception hierarchy under `Audd::Error`, mapping every AudD error code to a
  typed `Audd::ApiError` subclass and carrying the server's request echo.
- A project-specific `User-Agent`: `audd-ruby/<version> ruby/<ruby version> (<platform>)`.
- Contract tests running against the `AudDMusic/audd-openapi` spec and fixtures,
  vendored as a submodule pinned to `v1.4.4`.

`#recognize_enterprise` and `#find_lyrics` are stubbed and raise `NotImplementedError`.

## [0.1.0] - 2026-08-26

- Initial release
