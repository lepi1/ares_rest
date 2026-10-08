# AresRest

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

Other attributes: `ico`, `dic`, `city`, `zip`, `address`. There is also `to_h`.

Raises `AresRest::NotFoundError` when the IČO doesn't exist, `AresRest::InvalidIcoError` for a malformed IČO and `AresRest::Error` for anything else (network errors, timeouts). All of them inherit from `AresRest::Error`.

## Development

Run `bin/setup` to install dependencies, then `bundle exec rake` to run tests and RuboCop. `bin/console` gives you an interactive prompt.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lepi1/ares_rest. Contributors are expected to follow the [code of conduct](https://github.com/lepi1/ares_rest/blob/main/CODE_OF_CONDUCT.md).

## License

[MIT](https://opensource.org/licenses/MIT)
