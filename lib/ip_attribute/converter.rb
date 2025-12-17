# frozen_string_literal: true

require "ipaddr"

module IpAttribute
  # Standalone IP address converter — no ActiveRecord dependency.
  #
  # Type-dispatch design: branches by input class to avoid unnecessary
  # allocations. Integer input (the hot path when reading from DB)
  # never allocates a String or IPAddr.
  #
  # @example Convert string to integer
  #   IpAttribute::Converter.to_integer("192.168.0.1")  # => 3232235521
  #
  # @example Normalize IPv4-mapped IPv6
  #   IpAttribute::Converter.to_integer("::ffff:127.0.0.1", normalize_mapped: true)
  #   # => 2130706433 (IPv4 integer, not IPv6)
  #
  module Converter
    # Maximum valid IP integer: 2^128 - 1 (RFC 4291)
    MAX_IP = (2**128) - 1

    # Boundary between IPv4 and IPv6 (RFC 791 / RFC 4291)
    IPV4_MAX = (2**32) - 1

    # IPv4-mapped IPv6 prefix: ::ffff:0:0 (RFC 4291 §2.5.5.2)
    IPV4_MAPPED_PREFIX = 0xFFFF00000000

    # IPv4-mapped IPv6 range: ::ffff:0.0.0.0 to ::ffff:255.255.255.255
    IPV4_MAPPED_MIN = IPV4_MAPPED_PREFIX
    IPV4_MAPPED_MAX = IPV4_MAPPED_PREFIX + IPV4_MAX

    # Portable family enum — protocol version numbers from RFC 791/4291.
    # NOT Socket::AF_* constants (those are OS-specific: AF_INET6 is
    # 10 on Linux, 30 on macOS, 23 on Windows).
    FAMILY_IPV4 = 4
    FAMILY_IPV6 = 6

    # Map our portable enum to Socket constants for IPAddr construction
    FAMILY_TO_AF = {
      FAMILY_IPV4 => Socket::AF_INET,
      FAMILY_IPV6 => Socket::AF_INET6
    }.freeze

    # Map Socket constants to our portable enum for storage
    AF_TO_FAMILY = {
      Socket::AF_INET => FAMILY_IPV4,
      Socket::AF_INET6 => FAMILY_IPV6
    }.freeze

    # Maximum input string length accepted for parsing.
    MAX_INPUT_LENGTH = 64

    # Pattern matching a bare decimal integer.
    NUMERIC_PATTERN = /\A\d+\z/

    private_constant :MAX_INPUT_LENGTH, :NUMERIC_PATTERN

    module_function

    # Convert an IP address to its integer form.
    #
    # @param addr [String, Integer, IPAddr, nil] the address to convert
    # @param normalize_mapped [Boolean] collapse ::ffff:x.x.x.x to IPv4 integer
    # @return [Integer, nil] the integer representation, or nil for invalid/nil input
    def to_integer(addr, normalize_mapped: false)
      int = case addr
      when nil then return nil
      when Integer then addr
      when IPAddr then addr.to_i
      when String then parse_string(addr)
      else parse_string(addr.to_s)
      end

      return nil if int.nil?
      normalize_mapped ? demapped(int) : int
    end

    # Convert an integer to an IPAddr object.
    #
    # @param value [Integer, nil] the integer to convert
    # @param normalize_mapped [Boolean] collapse mapped addresses to IPv4
    # @return [IPAddr, nil] the IPAddr object, or nil for nil input
    # @raise [RangeError] if the integer is outside [0, 2^128-1]
    def to_ipaddr(value, normalize_mapped: false, family: nil)
      return nil if value.nil?

      int = value.to_i
      raise RangeError, "IP integer out of range: #{int}" if int.negative? || int > MAX_IP

      int = demapped(int) if normalize_mapped

      # Resolve address family: explicit portable enum → Socket constant,
      # or infer from integer range
      af = if family
        AddressFamily.to_socket(family) || family
      else
        (int <= IPV4_MAX) ? AddressFamily::AF_INET : AddressFamily.af_inet6
      end

      IPAddr.new(int, af)
    end

    # Check if an integer is in the IPv4-mapped IPv6 range.
    #
    # @param int [Integer] the integer to check
    # @return [Boolean]
    def mapped?(int)
      int.between?(IPV4_MAPPED_MIN, IPV4_MAPPED_MAX)
    end

    # Collapse IPv4-mapped IPv6 integer to its IPv4 equivalent.
    #
    # @param int [Integer] the integer to normalize
    # @return [Integer] IPv4 integer if mapped, original otherwise
    def demapped(int)
      mapped?(int) ? int - IPV4_MAPPED_PREFIX : int
    end

    # @api private
    def parse_string(str)
      return nil if str.empty?
      return nil if str.length > MAX_INPUT_LENGTH
      return nil if str.include?("/")
      return str.to_i if str.match?(NUMERIC_PATTERN)

      IPAddr.new(str).to_i
    rescue IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
      nil
    end

    private_class_method :parse_string
  end
end
