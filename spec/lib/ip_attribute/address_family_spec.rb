# frozen_string_literal: true

RSpec.describe IpAttribute::AddressFamily do
  describe ".af_inet6" do
    it "returns an integer for the current platform" do
      expect(described_class.af_inet6).to be_a(Integer)
      expect(described_class.af_inet6).to eq(Socket::AF_INET6)
    end
  end

  describe ".to_socket / .from_socket" do
    it "round-trips IPv4 family" do
      af = described_class.to_socket(IpAttribute::Converter::FAMILY_IPV4)
      expect(af).to eq(described_class::AF_INET)
      expect(described_class.from_socket(af)).to eq(IpAttribute::Converter::FAMILY_IPV4)
    end

    it "round-trips IPv6 family" do
      af = described_class.to_socket(IpAttribute::Converter::FAMILY_IPV6)
      expect(af).to eq(described_class.af_inet6)
      expect(described_class.from_socket(af)).to eq(IpAttribute::Converter::FAMILY_IPV6)
    end

    it "returns nil for unknown values" do
      expect(described_class.to_socket(99)).to be_nil
      expect(described_class.from_socket(99)).to be_nil
    end
  end
end
