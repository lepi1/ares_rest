## [Unreleased]

## [0.1.0] - 2026-10-08

- Initial release
- Add `AresRest.find` to look up a company by IČO
- Add `AresRest::Subject` with name, DIČ, registered address and the raw response via `data`
- Add `NotFoundError` and `InvalidIcoError`; network and parsing failures raise `AresRest::Error`
