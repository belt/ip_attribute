# frozen_string_literal: true

require "ip_attribute/core_ext"

RSpec.describe IpAttribute::CoreExt do
  using described_class

  describe "String#to_ip" do
    it "converts IPv4 string" do
      expect("127.0.0.1".to_ip).to eq(2_130_706_433)
    end

    it "returns nil for invalid" do
      expect("wuff".to_ip).to be_nil
    end
  end

  describe "Numeric#to_ip" do
    it "returns integer identity" do
      expect(42.to_ip).to eq(42)
    end
  end
end
