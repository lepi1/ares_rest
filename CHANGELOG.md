## [Unreleased]

## [0.1.0] - 2026-10-08

- Initial release
- Add `AresCz.find` to look up a company by IČO
- Add `AresCz::Company` with name, DIČ and registered address
- Add `NotFoundError` and `InvalidIcoError`; network and parsing failures raise `AresCz::Error`
