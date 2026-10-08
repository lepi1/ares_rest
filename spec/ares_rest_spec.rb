# frozen_string_literal: true

RSpec.describe AresRest do
  let(:endpoint) { "#{AresRest::BASE_URL}/ekonomicke-subjekty" }

  let(:company_body) do
    {
      "ico" => "12345678",
      "obchodniJmeno" => "Example s.r.o.",
      "dic" => "CZ12345678",
      "sidlo" => {
        "nazevObce" => "Praha",
        "nazevCastiObce" => "Nové Město",
        "nazevUlice" => "Hlavní",
        "cisloDomovni" => 123,
        "cisloOrientacni" => 4,
        "cisloOrientacniPismeno" => "a",
        "psc" => 11_000,
        "textovaAdresa" => "Hlavní 123/4a, Nové Město, 11000 Praha 1"
      }
    }
  end

  it "has a version number" do
    expect(AresRest::VERSION).not_to be_nil
  end

  describe ".find" do
    it "returns the company for an existing ICO" do
      stub_request(:get, "#{endpoint}/12345678").to_return(status: 200, body: company_body.to_json)

      company = described_class.find("12345678")

      expect(company.to_h).to eq(
        ico: "12345678",
        name: "Example s.r.o.",
        dic: "CZ12345678",
        street: "Hlavní 123/4a",
        city: "Praha",
        zip: "11000",
        address: "Hlavní 123/4a, Nové Město, 11000 Praha 1"
      )
    end

    it "strips whitespace and pads short ICOs with leading zeros" do
      stub = stub_request(:get, "#{endpoint}/00012345").to_return(status: 200, body: company_body.to_json)

      described_class.find(" 123 45 ")

      expect(stub).to have_been_requested
    end

    it "raises NotFoundError when ARES returns 404" do
      stub_request(:get, "#{endpoint}/12345678").to_return(status: 404, body: "{}")

      expect { described_class.find("12345678") }.to raise_error(AresRest::NotFoundError)
    end

    it "raises InvalidIcoError when ARES returns 400" do
      stub_request(:get, "#{endpoint}/12345678").to_return(status: 400, body: "{}")

      expect { described_class.find("12345678") }.to raise_error(AresRest::InvalidIcoError)
    end

    it "raises InvalidIcoError without calling ARES for malformed input" do
      ["abc", "123456789", "", "1/../x", nil].each do |ico|
        expect { described_class.find(ico) }.to raise_error(AresRest::InvalidIcoError)
      end
      expect(a_request(:any, /ares/)).not_to have_been_made
    end

    it "raises Error on unexpected HTTP status" do
      stub_request(:get, "#{endpoint}/12345678").to_return(status: 500)

      expect { described_class.find("12345678") }.to raise_error(AresRest::Error, /HTTP 500/)
    end

    it "wraps network errors in Error" do
      stub_request(:get, "#{endpoint}/12345678").to_timeout

      expect { described_class.find("12345678") }.to raise_error(AresRest::Error, /Communication error/)
    end

    it "wraps invalid JSON in Error" do
      stub_request(:get, "#{endpoint}/12345678").to_return(status: 200, body: "<html>")

      expect { described_class.find("12345678") }.to raise_error(AresRest::Error, /Invalid ARES response/)
    end
  end

  describe AresRest::Subject do
    def build(sidlo)
      described_class.new("ico" => "1", "sidlo" => sidlo)
    end

    it "uses the part of municipality when there is no street" do
      company = build("nazevObce" => "Lhota", "nazevCastiObce" => "Horní Lhota", "cisloDomovni" => 12)

      expect(company.street).to eq("Horní Lhota 12")
    end

    it "omits the orientation number when missing" do
      company = build("nazevObce" => "Brno", "nazevUlice" => "Hlavní", "cisloDomovni" => 5)

      expect(company.street).to eq("Hlavní 5")
    end

    it "exposes the raw ARES response" do
      result = described_class.new("ico" => "1", "datumVzniku" => "2020-01-01")

      expect(result.data["datumVzniku"]).to eq("2020-01-01")
    end

    it "leaves address fields nil without a seat" do
      company = described_class.new("ico" => "1", "obchodniJmeno" => "X")

      expect([company.street, company.city, company.zip]).to all(be_nil)
    end
  end
end
