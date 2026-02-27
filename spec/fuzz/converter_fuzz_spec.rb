# frozen_string_literal: false

# Rantly requires mutable strings — override the global
# RUBYOPT=--enable=frozen-string-literal for this file.

require "rantly"
require "rantly/rspec_extensions"

RSpec.describe "Converter fuzz", :fuzz do
  describe ".to_integer idempotency" do
    it "to_integer(to_integer(x)) == to_integer(x) for random IPs" do
      property_of {
        Rantly { choose("#{range(0, 255)}.#{range(0, 255)}.#{range(0, 255)}.#{range(0, 255)}") }
      }.check(200) { |ip|
        first = IpAttribute::Converter.to_integer(ip)
        second = IpAttribute::Converter.to_integer(first)
        expect(second).to eq(first), "Failed idempotency for #{ip}: #{first} != #{second}"
      }
    end
  end

  describe ".to_integer resilience" do
    it "never raises for random strings" do
      property_of {
        Rantly { sized(range(0, 100)) { string } }
      }.check(500) { |str|
        expect { IpAttribute::Converter.to_integer(str) }.not_to raise_error
      }
    end

    it "never raises for random integers" do
      property_of {
        Rantly { range(-1000, 2**130) }
      }.check(200) { |int|
        expect { IpAttribute::Converter.to_integer(int) }.not_to raise_error
      }
    end
  end

  describe ".to_ipaddr round-trip" do
    it "round-trips random IPv4 integers" do
      property_of {
        Rantly { range(0, 2**32 - 1) }
      }.check(200) { |int|
        ip = IpAttribute::Converter.to_ipaddr(int)
        expect(ip).to be_a(IPAddr)
        expect(IpAttribute::Converter.to_integer(ip)).to eq(int)
      }
    end
  end

  describe ".mapped? boundary" do
    it "correctly classifies random integers around the mapped range" do
      mapped_min = IpAttribute::Converter::IPV4_MAPPED_PREFIX
      mapped_max = mapped_min + (2**32 - 1)

      property_of {
        Rantly { choose(range(0, mapped_min - 1), range(mapped_min, mapped_max), range(mapped_max + 1, 2**128 - 1)) }
      }.check(300) { |int|
        result = IpAttribute::Converter.mapped?(int)
        expected = int.between?(mapped_min, mapped_max)
        expect(result).to eq(expected), "mapped?(#{int}) = #{result}, expected #{expected}"
      }
    end
  end
end
