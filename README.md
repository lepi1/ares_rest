# AresRest

[![Gem Version](https://img.shields.io/gem/v/ares_rest)](https://rubygems.org/gems/ares_rest)
[![CI](https://github.com/lepi1/ares_rest/actions/workflows/main.yml/badge.svg?branch=master)](https://github.com/lepi1/ares_rest/actions/workflows/main.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)

Simple Ruby client for the Czech [ARES](https://ares.gov.cz/) registry. Finds a company by IČO.

## Installation

```ruby
gem "ares_rest", github: "lepi1/ares_rest"
```

## Usage

```ruby
company = AresRest.find("12345678")
company.name   # => "Example s.r.o."
company.street # => "Hlavní 123/4"
```

Returns an `AresRest::Subject`. Other attributes: `ico`, `dic`, `city`, `postal_code`, `address`. There is also `to_h`.

For fields not mapped yet, use the raw ARES response:

```ruby
company.data["datumVzniku"] # => "2020-01-01"
```

Raises `AresRest::NotFoundError` when the IČO doesn't exist, `AresRest::InvalidIcoError` for a malformed IČO and `AresRest::Error` for anything else (network errors, timeouts). All of them inherit from `AresRest::Error`.

## Development

Run `bin/setup` to install dependencies, then `bundle exec rake` to run tests and RuboCop. `bin/console` gives you an interactive prompt.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lepi1/ares_rest. Contributors are expected to follow the [code of conduct](https://github.com/lepi1/ares_rest/blob/master/CODE_OF_CONDUCT.md).

## License

[MIT](https://opensource.org/licenses/MIT)
