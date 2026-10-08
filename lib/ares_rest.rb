# frozen_string_literal: true

require "json"
require "net/http"
require "openssl"
require "uri"
require_relative "ares_rest/version"

# Module for calling Ares API
# https://ares.gov.cz/swagger-ui/#/
#
# @example
#   subject = AresRest.find("12345678")
#   subject.name   # => "Example s.r.o."
#   subject.street # => "Hlavní 123/4"
module AresRest
  # Base class for all errors raised by this gem.
  class Error < StandardError; end

  # Raised when ARES has no subject with the given IČO.
  class NotFoundError < Error; end

  # Raised when the IČO is malformed or ARES rejects it.
  class InvalidIcoError < Error; end

  BASE_URL = "https://ares.gov.cz/ekonomicke-subjekty-v-be/rest"
  BY_ICO_ENDPOINT = "#{BASE_URL}/ekonomicke-subjekty/%s".freeze
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 10
  NETWORK_ERRORS = [
    SocketError, Timeout::Error, IOError, SystemCallError, OpenSSL::SSL::SSLError
  ].freeze
  private_constant :BASE_URL, :BY_ICO_ENDPOINT, :OPEN_TIMEOUT, :READ_TIMEOUT, :NETWORK_ERRORS

  # Economic subject (company, sole trader, association, ...) returned by ARES.
  # The full parsed response is available via {#data}.
  class Subject
    # @return [String, nil] IČO, 8 digits
    attr_reader :ico

    # @return [String, nil] business name (obchodní jméno)
    attr_reader :name

    # @return [String, nil] VAT number (DIČ), e.g. "CZ12345678"
    attr_reader :dic

    # @return [String, nil] street with house number, e.g. "Hlavní 123/4a"
    attr_reader :street

    # @return [String, nil] municipality (název obce), without district,
    #   e.g. "Praha" even for an address in Praha 4
    attr_reader :city

    # @return [String, nil] postal code (PSČ) without spaces, e.g. "11000"
    attr_reader :postal_code

    # @return [String, nil] full one-line address as formatted by ARES
    attr_reader :address

    # Raw parsed ARES response, for fields without their own accessor.
    #
    # @example
    #   subject.data["datumVzniku"] # => "2020-01-01"
    # @return [Hash{String => Object}]
    attr_reader :data

    # @api private
    # @param data [Hash{String => Object}] parsed ARES response
    def initialize(data)
      @data = data
      @ico = data["ico"]
      @name = data["obchodniJmeno"]
      @dic = data["dic"]
      assign_address(data["sidlo"]) if data["sidlo"]
    end

    # @return [Hash{Symbol => String, nil}] mapped attributes, without {#data}
    def to_h
      { ico: ico, name: name, dic: dic, street: street, city: city, postal_code: postal_code, address: address }
    end

    private

    def assign_address(location)
      street = location["nazevUlice"] || location["nazevCastiObce"] || location["nazevObce"]

      @street = "#{street} #{build_street_number_from(location)}".strip
      @city = location["nazevObce"]
      @postal_code = location["psc"]&.to_s&.gsub(/\s+/, "")
      @address = location["textovaAdresa"]
    end

    def build_street_number_from(location)
      orientacni = "#{location["cisloOrientacni"]}#{location["cisloOrientacniPismeno"]}"
      [location["cisloDomovni"], orientacni].map(&:to_s).reject(&:empty?).join("/")
    end
  end

  # Looks up an economic subject by IČO.
  #
  # @param ico [String, Integer] 1-8 digits; whitespace is stripped and
  #   shorter numbers are padded with leading zeros
  # @return [Subject]
  # @raise [InvalidIcoError] if the IČO is malformed
  # @raise [NotFoundError] if no subject has this IČO
  # @raise [Error] on network failure, timeout or an unexpected response
  # @example
  #   AresRest.find("12345678").name # => "Example s.r.o."
  def self.find(ico)
    response = get(URI(format(BY_ICO_ENDPOINT, normalize_ico(ico))))

    case response.code
    when "200" then Subject.new(JSON.parse(response.body))
    when "404" then raise NotFoundError, "Cannot find subject with ICO #{ico}"
    when "400" then raise InvalidIcoError, "ARES rejected ICO #{ico}"
    else raise Error, "Unexpected ARES response: HTTP #{response.code}"
    end
  rescue JSON::ParserError => e
    raise Error, "Invalid ARES response: #{e.message}"
  end

  def self.normalize_ico(ico)
    normalized = ico.to_s.gsub(/\s+/, "")
    raise InvalidIcoError, "ICO must be 1-8 digits, got #{ico.inspect}" unless normalized.match?(/\A\d{1,8}\z/)

    normalized.rjust(8, "0")
  end

  def self.get(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
      http.request(Net::HTTP::Get.new(uri, "Accept" => "application/json"))
    end
  rescue *NETWORK_ERRORS => e
    raise Error, "Communication error: #{e.message}"
  end

  private_class_method :normalize_ico, :get
end
