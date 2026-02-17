# frozen_string_literal: true

require "active_record"
require "ip_attribute/active_record_integration"

RSpec.describe IpAttribute::ActiveRecordIntegration do
  describe "Strategy B: single column (range inference)" do
    include_context "single column AR"

    it "round-trips IPv4" do
      user.login_ip = "192.168.0.1"
      expect(user.login_ip.to_s).to eq("192.168.0.1")
      expect(user.login_ip.ipv4?).to be true
    end

    it "round-trips IPv6" do
      user.login_ip = "2001:db8::1"
      expect(user.login_ip.ipv6?).to be true
    end

    it "maps ::1 to IPv4 0.0.0.1 (known limitation without family)" do
      user.login_ip = "::1"
      expect(user.login_ip.to_s).to eq("0.0.0.1")
    end

    it "persists through save/reload" do
      user.login_ip = "10.0.0.1"
      user.save!
      expect(TestUser.find(user.id).login_ip.to_s).to eq("10.0.0.1")
    end

    it "provides _display helper" do
      user.login_ip = "10.0.0.1"
      expect(user.login_ip_display).to eq("10.0.0.1")
    end

    it "handles nil" do
      user.login_ip = nil
      expect(user.login_ip).to be_nil
      expect(user.login_ip_display).to be_nil
    end
  end

  describe "Strategy B: single column + family (perfect round-trip)" do
    include_context "single column + family AR"

    it "round-trips ::1 as IPv6 (not 0.0.0.1)" do
      user.login_ip = "::1"
      expect(user.login_ip.to_s).to eq("::1")
      expect(user.login_ip.ipv6?).to be true
    end

    it "stores family in _ip_family column" do
      user.login_ip = "::1"
      expect(user.read_attribute(:login_ip_family)).to eq(IpAttribute::Converter::FAMILY_IPV6)

      user.login_ip = "127.0.0.1"
      expect(user.read_attribute(:login_ip_family)).to eq(IpAttribute::Converter::FAMILY_IPV4)
    end

    it "round-trips IPv4" do
      user.login_ip = "10.0.0.1"
      expect(user.login_ip.to_s).to eq("10.0.0.1")
      expect(user.login_ip.ipv4?).to be true
    end

    it "clears family on nil" do
      user.login_ip = "10.0.0.1"
      user.login_ip = nil
      expect(user.read_attribute(:login_ip_family)).to be_nil
    end
  end

  describe "Strategy A: dual column (_ipv4 bigint + _ipv6 decimal)" do
    include_context "dual column AR"

    it "stores IPv4 in _ipv4 column" do
      session.client_ipv4 = "192.168.0.1"
      expect(session.read_attribute(:client_ipv4)).to eq(3_232_235_521)
      expect(session.client_ipv4.to_s).to eq("192.168.0.1")
      expect(session.client_ipv4.ipv4?).to be true
    end

    it "stores IPv6 in _ipv6 column" do
      session.client_ipv6 = "2001:db8::1"
      expect(session.read_attribute(:client_ipv6)).to be > 0
      expect(session.client_ipv6.ipv6?).to be true
    end

    it "stores ::1 as IPv6 (not IPv4 0.0.0.1)" do
      session.client_ipv6 = "::1"
      expect(session.client_ipv6.to_s).to eq("::1")
      expect(session.client_ipv6.ipv6?).to be true
      expect(session.read_attribute(:client_ipv6)).to eq(1)
    end

    it "normalizes ::ffff:127.0.0.1 to IPv4 in _ipv4 writer" do
      session.client_ipv4 = "::ffff:127.0.0.1"
      expect(session.read_attribute(:client_ipv4)).to eq(2_130_706_433)
      expect(session.client_ipv4.ipv4?).to be true
    end

    it "rejects mapped in _ipv6 writer (normalizes to nil)" do
      session.client_ipv6 = "::ffff:127.0.0.1"
      expect(session.read_attribute(:client_ipv6)).to be_nil
    end

    it "rejects IPv6 in _ipv4 writer (stores nil)" do
      session.client_ipv4 = "2001:db8::1"
      expect(session.read_attribute(:client_ipv4)).to be_nil
    end

    it "rejects IPv4 in _ipv6 writer (stores nil)" do
      session.client_ipv6 = "192.168.0.1"
      expect(session.read_attribute(:client_ipv6)).to be_nil
    end

    it "stores nil for invalid input in both writers" do
      session.client_ipv4 = "wuff"
      session.client_ipv6 = "wuff"
      expect(session.read_attribute(:client_ipv4)).to be_nil
      expect(session.read_attribute(:client_ipv6)).to be_nil
    end

    it "supports dual-stack (both populated)" do
      session.client_ipv4 = "192.168.0.50"
      session.client_ipv6 = "2001:db8::50"
      expect(session.client_ipv4.to_s).to eq("192.168.0.50")
      expect(session.client_ipv6.to_s).to eq("2001:db8::50")
    end

    it "handles nil independently" do
      session.client_ipv4 = "10.0.0.1"
      session.client_ipv6 = "::1"
      session.client_ipv4 = nil
      expect(session.client_ipv4).to be_nil
      expect(session.client_ipv6.to_s).to eq("::1")
    end

    it "provides combined display" do
      session.client_ipv4 = "10.0.0.1"
      session.client_ipv6 = "2001:db8::1"
      expect(session.client_ip_display).to eq("10.0.0.1 / 2001:db8::1")
    end
  end

  describe "error on no IP columns" do
    it "raises IpAttribute::Error" do
      ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
      ActiveRecord::Schema.define do
        create_table :no_ip_models, force: true do |t|
          t.string :name
        end
      end

      expect {
        Class.new(ActiveRecord::Base) do
          self.table_name = "no_ip_models"
          include IpAttribute::ActiveRecordIntegration
        end
      }.to raise_error(IpAttribute::Error)
    end
  end
end
