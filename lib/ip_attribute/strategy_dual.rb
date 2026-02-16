# frozen_string_literal: true

module IpAttribute
  # Strategy A installer: dual column (prefix_ipv4 bigint + prefix_ipv6 decimal).
  # Both can be populated (dual-stack per RFC 4291 §2.1).
  # Mapped addresses normalize to IPv4 via IPAddr#native.
  module StrategyDual
    private

    def _install_dual(prefix)
      _install_dual_validations(prefix)
      _install_dual_accessors(prefix)
      _install_dual_display(prefix)
    end

    def _install_dual_validations(prefix)
      validates_numericality_of "#{prefix}_ipv4",
        only_integer: true, allow_nil: true,
        greater_than_or_equal_to: 0, less_than_or_equal_to: Converter::IPV4_MAX

      validates_numericality_of "#{prefix}_ipv6",
        only_integer: true, allow_nil: true,
        greater_than_or_equal_to: 0, less_than_or_equal_to: Converter::MAX_IP
    end

    def _install_dual_accessors(prefix)
      ipv4_col = "#{prefix}_ipv4"
      ipv6_col = "#{prefix}_ipv6"

      _define_ip_reader(ipv4_col, family: Converter::FAMILY_IPV4)
      _define_ip_reader(ipv6_col, family: Converter::FAMILY_IPV6)

      define_method(:"#{ipv4_col}=") do |addr|
        write_attribute(ipv4_col, _ipv4_int(_ip_parse(addr)))
      end

      define_method(:"#{ipv6_col}=") do |addr|
        write_attribute(ipv6_col, _ipv6_int(_ip_parse(addr)))
      end
    end

    def _install_dual_display(prefix)
      ipv4_col = "#{prefix}_ipv4"
      ipv6_col = "#{prefix}_ipv6"

      define_method("#{prefix}_ip_display") do
        parts = [public_send(ipv4_col)&.to_s, public_send(ipv6_col)&.to_s].compact
        parts.empty? ? nil : parts.join(" / ")
      end
    end
  end
end
