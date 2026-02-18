# frozen_string_literal: true

RSpec.describe IpAttribute::Error do
  it { expect(described_class).to be < StandardError }
end

RSpec.describe IpAttribute::ConversionError do
  it "stores value and inherits from Error" do
    error = described_class.new("bad")
    expect(error).to be_a(IpAttribute::Error)
    expect(error.value).to eq("bad")
    expect(error.message).to include("bad")
  end
end
