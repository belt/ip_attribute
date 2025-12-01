# frozen_string_literal: true

RSpec.describe IpAttribute::Converter do
  describe ".to_integer" do
    # IPv4 (RFC 791)
    include_examples "converts to integer", "127.0.0.1", 2_130_706_433
    include_examples "converts to integer", "0.0.0.0", 0
    include_examples "converts to integer", "255.255.255.255", (2**32 - 1)
    include_examples "converts to integer", "10.0.0.1", 167_772_161

    # IPv6 (RFC 4291)
    include_examples "converts to integer", "::1", 1
    include_examples "converts to integer", "::", 0
    include_examples "converts to integer", "3FFE:505:2::1", 85_060_308_944_708_794_891_899_627_827_609_206_785

    # IPv4-mapped IPv6 (RFC 4291 §2.5.5.2)
    it "stores ::ffff:127.0.0.1 as IPv6 integer" do
      result = described_class.to_integer("::ffff:127.0.0.1")
      expect(result).to be > (2**32 - 1)
    end

    # Type dispatch
    include_examples "converts to integer", 2_130_706_433, 2_130_706_433
    include_examples "converts to integer", "2130706433", 2_130_706_433

    it "converts IPAddr object" do
      expect(described_class.to_integer(IPAddr.new("10.0.0.1"))).to eq(167_772_161)
    end

    it "falls back to to_s for unknown types" do
      expect(described_class.to_integer(double(to_s: "10.0.0.1"))).to eq(167_772_161)
    end

    # Invalid input
    include_examples "returns nil for invalid", nil
    include_examples "returns nil for invalid", ""
    include_examples "returns nil for invalid", "wuff"
    include_examples "returns nil for invalid", "1.5"
    include_examples "returns nil for invalid", "192.168.0.0/24"
    include_examples "returns nil for invalid", "2001:db8::/32"
    include_examples "returns nil for invalid", ("1" * 100)

    # RFC 4291 text representation equivalence
    it "preferred and compressed forms produce same integer" do
      expect(described_class.to_integer("2001:0DB8:0000:0000:0008:0800:200C:417A"))
        .to eq(described_class.to_integer("2001:DB8::8:800:200C:417A"))
    end
  end

  describe ".to_ipaddr" do
    include_examples "round-trips through IPAddr", "127.0.0.1", :ipv4
    include_examples "round-trips through IPAddr", "255.255.255.255", :ipv4
    include_examples "round-trips through IPAddr", "3FFE:505:2::1", :ipv6

    it "returns nil for nil" do
      expect(described_class.to_ipaddr(nil)).to be_nil
    end

    it "raises RangeError for negative" do
      expect { described_class.to_ipaddr(-1) }.to raise_error(RangeError)
    end

    it "raises RangeError for > 2^128-1" do
      expect { described_class.to_ipaddr(2**128) }.to raise_error(RangeError)
    end

    it "maps integer 1 to IPv4 0.0.0.1 (not IPv6 ::1)" do
      result = described_class.to_ipaddr(1)
      expect(result.ipv4?).to be true
      expect(result.to_s).to eq("0.0.0.1")
    end
  end

  describe "normalize_mapped: true" do
    it "collapses ::ffff:127.0.0.1 to IPv4 integer" do
      result = described_class.to_integer("::ffff:127.0.0.1", normalize_mapped: true)
      expect(result).to eq(2_130_706_433)
    end

    it "returns IPv4 IPAddr for mapped integer" do
      mapped = IPAddr.new("::ffff:10.0.0.1").to_i
      result = described_class.to_ipaddr(mapped, normalize_mapped: true)
      expect(result.ipv4?).to be true
      expect(result.to_s).to eq("10.0.0.1")
    end

    it "leaves non-mapped addresses unchanged" do
      int = described_class.to_integer("2001:db8::1")
      result = described_class.to_integer("2001:db8::1", normalize_mapped: true)
      expect(result).to eq(int)
    end
  end

  describe ".mapped? / .demapped" do
    it "detects and extracts IPv4 from mapped" do
      mapped = IPAddr.new("::ffff:192.168.0.1").to_i
      expect(described_class.mapped?(mapped)).to be true
      expect(described_class.demapped(mapped)).to eq(3_232_235_521)
    end

    it "returns false/identity for non-mapped" do
      expect(described_class.mapped?(42)).to be false
      expect(described_class.demapped(42)).to eq(42)
    end
  end
end
