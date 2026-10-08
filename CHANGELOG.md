## [Unreleased]

## [0.1.0] - 2026-10-08

- Initial release
- Add `AresRest.find` to look up a company by IČO
- Add `AresRest::Company` with name, DIČ and registered address
- Add `NotFoundError` and `InvalidIcoError`; network and parsing failures raise `AresRest::Error`
