# frozen_string_literal: true

require_relative "converter"

module IpAttribute
  # Opt-in refinements for String#to_ip and Numeric#to_ip.
  #
  # These are lexically scoped — they only apply in files that opt in
  # with `using IpAttribute::CoreExt`. No global monkey-patching.
  #
  # @example
  #   require "ip_attribute/core_ext"
  #   using IpAttribute::CoreExt
  #
  #   "192.168.0.1".to_ip   # => 3232235521
  #   2130706433.to_ip      # => 2130706433
  #
  module CoreExt
    refine String do
      # @return [Integer, nil] the integer representation of this IP string
      def to_ip
        IpAttribute::Converter.to_integer(self)
      end
    end

    refine Numeric do
      # @return [Integer, nil] the integer representation (identity for valid IPs)
      def to_ip
        IpAttribute::Converter.to_integer(self)
      end
    end
  end
end
