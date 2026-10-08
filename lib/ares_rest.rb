# frozen_string_literal: true

require "json"
require "net/http"
require "openssl"
require "uri"
require_relative "ares_rest/version"

# Module for calling Ares API
# https://ares.gov.cz/swagger-ui/#/
module AresRest
  class Error < StandardError; end
  class NotFoundError < Error; end
  class InvalidIcoError < Error; end
  BASE_URL = "https://ares.gov.cz/ekonomicke-subjekty-v-be/rest"
  BY_ICO_ENDPOINT = "#{BASE_URL}/ekonomicke-subjekty/%s".freeze
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 10
  NETWORK_ERRORS = [
    SocketError, Timeout::Error, IOError, SystemCallError, OpenSSL::SSL::SSLError
  ].freeze

  # Economic subject (company, sole trader, association, ...) returned by ARES.
  # The full parsed response is available via #data.
  class Subject
    attr_reader :ico, :name, :dic, :street, :city, :zip, :address, :data

    def initialize(data)
      @data = data
      @ico = data["ico"]
      @name = data["obchodniJmeno"]
      @dic = data["dic"]
      assign_address(data["sidlo"]) if data["sidlo"]
    end

    def to_h
      { ico: ico, name: name, dic: dic, street: street, city: city, zip: zip, address: address }
    end

    private

    def assign_address(location)
      street = location["nazevUlice"] || location["nazevCastiObce"] || location["nazevObce"]

      @street = "#{street} #{build_street_number_from(location)}".strip
      @city = location["nazevObce"]
      @zip = location["psc"]&.to_s&.gsub(/\s+/, "")
      @address = location["textovaAdresa"]
    end

    def build_street_number_from(location)
      orientacni = "#{location["cisloOrientacni"]}#{location["cisloOrientacniPismeno"]}"
      [location["cisloDomovni"], orientacni].map(&:to_s).reject(&:empty?).join("/")
    end
  end

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
