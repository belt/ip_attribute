# frozen_string_literal: true

require "active_model"
require "ip_attribute/type"

RSpec.describe IpAttribute::Type do
  subject(:type) { described_class.new }

  describe "#type" do
    it { expect(type.type).to eq(:ip_address) }
  end

  describe "#cast" do
    it "casts string to IPAddr" do
      expect(type.cast("127.0.0.1")).to be_a(IPAddr)
    end

    it("nil → nil") { expect(type.cast(nil)).to be_nil }
    it("invalid → nil") { expect(type.cast("wuff")).to be_nil }
    it("IPAddr passthrough") { expect(type.cast(IPAddr.new("10.0.0.1"))).to be_a(IPAddr) }
  end

  describe "#serialize / #deserialize" do
    it "round-trips string → integer → IPAddr" do
      int = type.serialize("127.0.0.1")
      expect(int).to eq(2_130_706_433)

      ip = type.deserialize(int)
      expect(ip.to_s).to eq("127.0.0.1")
    end

    it("nil → nil") { expect(type.serialize(nil)).to be_nil }
    it("nil → nil") { expect(type.deserialize(nil)).to be_nil }
  end

  describe "#changed_in_place?" do
    it("detects change") { expect(type.changed_in_place?(1, "10.0.0.1")).to be true }
    it("detects same") { expect(type.changed_in_place?(2_130_706_433, "127.0.0.1")).to be false }
  end

  context "normalize_mapped: true" do
    subject(:type) { described_class.new(normalize_mapped: true) }

    it "collapses mapped addresses" do
      mapped = IPAddr.new("::ffff:10.0.0.1").to_i
      expect(type.deserialize(mapped).ipv4?).to be true
      expect(type.serialize("::ffff:10.0.0.1")).to eq(167_772_161)
    end
  end

  context "ActiveModel::Attributes integration" do
    let(:klass) do
      Class.new do
        include ActiveModel::Model
        include ActiveModel::Attributes

        attribute :client_ip, IpAttribute::Type.new

        def self.name = "TestModel"
      end
    end

    it "casts on assignment and handles nil" do
      obj = klass.new(client_ip: "192.168.0.1")
      expect(obj.client_ip.to_s).to eq("192.168.0.1")

      obj = klass.new(client_ip: nil)
      expect(obj.client_ip).to be_nil
    end
  end
end
