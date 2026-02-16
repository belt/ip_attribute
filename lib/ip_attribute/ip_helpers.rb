# frozen_string_literal: true

module IpAttribute
  # Instance methods mixed into AR models for IP parsing and
  # family-specific integer extraction. Defined once, shared
  # by both dual and single column strategies.
  module IpHelpers
    private

    # Parse any input into IPAddr. Returns nil for invalid/nil.
    def _ip_parse(addr)
      return nil if addr.nil?
      return addr if addr.is_a?(IPAddr)
      IPAddr.new(addr.to_s)
    rescue IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
      nil
    end

    # Extract IPv4 integer (handles plain IPv4 + mapped).
    def _ipv4_int(ip_addr)
      return ip_addr.to_i if ip_addr&.ipv4?
      return ip_addr.native.to_i if ip_addr&.ipv4_mapped?
      nil
    end

    # Extract IPv6 integer (rejects mapped — those go to _ipv4).
    def _ipv6_int(ip_addr)
      (ip_addr&.ipv6? && !ip_addr&.ipv4_mapped?) ? ip_addr.to_i : nil
    end
  end
end
