# frozen_string_literal: true

RSpec.shared_examples "converts to integer" do |input, expected|
  it "#{input.inspect} → #{expected}" do
    expect(IpAttribute::Converter.to_integer(input)).to eq(expected)
  end
end

RSpec.shared_examples "returns nil for invalid" do |input|
  it "#{input.inspect} → nil" do
    expect(IpAttribute::Converter.to_integer(input)).to be_nil
  end
end

RSpec.shared_examples "round-trips through IPAddr" do |input_str, expected_family|
  it "#{input_str} round-trips as #{expected_family}" do
    int = IpAttribute::Converter.to_integer(input_str)
    ip = IpAttribute::Converter.to_ipaddr(int)
    expect(ip).to be_a(IPAddr)
    expect(ip.public_send(:"#{expected_family}?")).to be true
  end
end
