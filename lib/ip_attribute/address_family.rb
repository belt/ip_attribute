# frozen_string_literal: true

module IpAttribute
  # OS-aware address family constants.
  #
  # AF_INET (2) is universal. AF_INET6 varies by kernel.
  # Common platforms are hardcoded for zero-overhead lookup.
  # Exotic platforms fall back to etc/address_families.jsonc.
  #
  # The portable family enum (4/6) stored in the database is
  # independent of these OS constants — this module maps between
  # the two layers.
  #
  module AddressFamily
    AF_INET = 2 # Universal across all POSIX (RFC 791)

    # Hardcoded AF_INET6 by RUBY_PLATFORM prefix.
    # Covers >99% of deployments without file I/O.
    HARDCODED_AF_INET6 = {
      "linux" => 10,
      "darwin" => 30,
      "freebsd" => 28,
      "openbsd" => 24,
      "netbsd" => 24,
      "mingw" => 23,
      "mswin" => 23
    }.freeze

    class << self
      # AF_INET6 for the current platform.
      # @return [Integer]
      def af_inet6
        @af_inet6 ||= resolve_af_inet6
      end

      # Portable enum (4/6) → OS socket constant.
      # Built lazily so af_inet6 is resolved before first use.
      # @param family [Integer] 4 or 6
      # @return [Integer, nil]
      def to_socket(family)
        enum_to_af[family]
      end

      # OS socket constant → portable enum (4/6).
      # @param af [Integer] Socket::AF_INET or AF_INET6
      # @return [Integer, nil]
      def from_socket(af)
        af_to_enum[af]
      end

      private

      def enum_to_af
        @enum_to_af ||= {
          Converter::FAMILY_IPV4 => AF_INET,
          Converter::FAMILY_IPV6 => af_inet6
        }.freeze
      end

      def af_to_enum
        @af_to_enum ||= {
          AF_INET => Converter::FAMILY_IPV4,
          af_inet6 => Converter::FAMILY_IPV6
        }.freeze
      end

      def resolve_af_inet6
        platform = RUBY_PLATFORM.downcase
        HARDCODED_AF_INET6.each do |prefix, value|
          return value if platform.include?(prefix)
        end

        load_from_config(platform)
      end

      def load_from_config(platform)
        config_path = File.expand_path("../../etc/address_families.jsonc", __dir__)
        return Socket::AF_INET6 unless File.exist?(config_path)

        require "json"
        raw = File.read(config_path).gsub(%r{//.*$}, "")
        data = JSON.parse(raw)
        table = data["af_inet6_by_os"] || {}

        table.each do |os, value|
          return value if platform.include?(os)
        end

        Socket::AF_INET6
      end
    end
  end
end
