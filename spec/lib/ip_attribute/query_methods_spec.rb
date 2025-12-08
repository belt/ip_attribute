# frozen_string_literal: true

require "active_record"
require "ip_attribute/active_record_integration"

RSpec.describe IpAttribute::QueryMethods do
  include_context "single column AR"

  before do
    TestUser.delete_all
    %w[192.168.0.1 192.168.0.100 10.0.0.1 192.168.1.1].each do |ip|
      TestUser.create!(login_ip: ip)
    end
  end

  describe ".where_ip" do
    it "filters by /24 subnet" do
      expect(TestUser.where_ip(:login_ip, "192.168.0.0/24").count).to eq(2)
    end

    it "filters by /16 subnet" do
      expect(TestUser.where_ip(:login_ip, "192.168.0.0/16").count).to eq(3)
    end

    it "returns empty for non-matching subnet" do
      expect(TestUser.where_ip(:login_ip, "172.16.0.0/12")).to be_empty
    end
  end
end
