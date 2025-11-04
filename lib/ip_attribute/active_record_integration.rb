# frozen_string_literal: true

require "active_support/concern"

module IpAttribute
  # ActiveRecord integration for automatic IP attribute handling.
  #
  # Auto-detects storage strategy from column naming convention:
  #
  # Strategy A — Dual column (login_ipv4 bigint + login_ipv6 decimal):
  #   Unambiguous family. Exactly one column populated per row.
  #   Detected when both _ipv4 and _ipv6 columns exist with matching prefix.
  #
  # Strategy B — Single column + optional family (login_ip decimal):
  #   If login_ip_family column exists: explicit family, perfect round-trip.
  #   If login_ip_family missing: range inference fallback (v0.1.0 compat).
  #
  # @example Single column (Strategy B)
  #   class User < ActiveRecord::Base
  #     include IpAttribute::ActiveRecordIntegration
  #   end
  #
  # @example Dual column (Strategy A)
  #   class Session < ActiveRecord::Base
  #     # has client_ipv4 (bigint) + client_ipv6 (decimal) columns
  #     include IpAttribute::ActiveRecordIntegration
  #   end
  #
  module ActiveRecordIntegration
    extend ActiveSupport::Concern

    included do
      extend IpAttribute::QueryMethods

      cols = column_names
      dual_prefixes = detect_dual_columns(cols)
      single_columns = cols.grep(/_ip\z/)

      if dual_prefixes.empty? && single_columns.empty?
        raise IpAttribute::Error,
          "#{name} has no IP columns — need _ip, or _ipv4/_ipv6 pairs"
      end

      # Strategy A: dual columns
      dual_prefixes.each { |prefix| install_dual(prefix) }

      # Strategy B: single columns (exclude those already handled by dual)
      dual_names = dual_prefixes.flat_map { |p| ["#{p}_ipv4", "#{p}_ipv6"] }
      single_columns.reject { |c| dual_names.include?(c) }.each do |col|
        family_col = "#{col}_family"
        has_family = cols.include?(family_col)
        install_single(col, family_col: has_family ? family_col : nil)
      end
    end

    class_methods do
      private

      # Detect _ipv4/_ipv6 column pairs, return their shared prefixes.
      def detect_dual_columns(cols)
        v4 = cols.grep(/_ipv4\z/).map { |c| c.delete_suffix("_ipv4") }
        v6 = cols.grep(/_ipv6\z/).map { |c| c.delete_suffix("_ipv6") }
        (v4 & v6).freeze
      end

      # Strategy A: dual column (prefix_ipv4 bigint + prefix_ipv6 decimal)
      #
      # Both columns can be populated (dual-stack interface per RFC 4291).
      # Both can be NULL. Mapped addresses (::ffff:x.x.x.x) normalize
      # to IPv4 via IPAddr#native — stored in _ipv4, not _ipv6.
      def install_dual(prefix)
        v4_col = "#{prefix}_ipv4"
        v6_col = "#{prefix}_ipv6"
        v4_accessor = v4_col
        v6_accessor = v6_col
        v4_writer = :"#{v4_col}="
        v6_writer = :"#{v6_col}="
        display = "#{prefix}_ip_display"

        validates_numericality_of v4_col,
          only_integer: true, allow_nil: true,
          greater_than_or_equal_to: 0, less_than_or_equal_to: Converter::IPV4_MAX

        validates_numericality_of v6_col,
          only_integer: true, allow_nil: true,
          greater_than_or_equal_to: 0, less_than_or_equal_to: Converter::MAX_IP

        # IPv4 reader
        define_method(v4_accessor) do
          raw = read_attribute_before_type_cast(v4_col)
          raw ? Converter.to_ipaddr(raw, family: Converter::FAMILY_IPV4) : nil
        rescue RangeError
          nil
        end

        # IPv6 reader
        define_method(v6_accessor) do
          raw = read_attribute_before_type_cast(v6_col)
          raw ? Converter.to_ipaddr(raw, family: Converter::FAMILY_IPV6) : nil
        rescue RangeError
          nil
        end

        # IPv4 writer: accepts string/IPAddr/integer, normalizes mapped
        define_method(v4_writer) do |addr|
          if addr.nil?
            write_attribute(v4_col, nil)
            return
          end

          ip = addr.is_a?(IPAddr) ? addr : begin
            IPAddr.new(addr.to_s)
          rescue IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
            nil
          end

          if ip.nil?
            write_attribute(v4_col, nil)
          elsif ip.ipv4?
            write_attribute(v4_col, ip.to_i)
          elsif ip.ipv4_mapped?
            write_attribute(v4_col, ip.native.to_i)
          else
            # IPv6 address assigned to IPv4 column — store nil
            write_attribute(v4_col, nil)
          end
        end

        # IPv6 writer: accepts string/IPAddr/integer
        define_method(v6_writer) do |addr|
          if addr.nil?
            write_attribute(v6_col, nil)
            return
          end

          ip = addr.is_a?(IPAddr) ? addr : begin
            IPAddr.new(addr.to_s)
          rescue IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
            nil
          end

          if ip.nil?
            write_attribute(v6_col, nil)
          elsif ip.ipv6? && !ip.ipv4_mapped?
            write_attribute(v6_col, ip.to_i)
          elsif ip.ipv4_mapped?
            # Mapped → normalize to IPv4, don't store in v6
            write_attribute(v6_col, nil)
          else
            # IPv4 address assigned to IPv6 column — store nil
            write_attribute(v6_col, nil)
          end
        end

        # Display: prefer IPv4, fall back to IPv6
        define_method(display) do
          v4 = public_send(v4_accessor)
          v6 = public_send(v6_accessor)
          [v4&.to_s, v6&.to_s].compact.join(" / ").then { |s| s.empty? ? nil : s }
        end
      end

      # Strategy B: single column + optional family
      def install_single(col, family_col: nil)
        col_writer = :"#{col}="

        validates_numericality_of col,
          only_integer: true, allow_nil: true,
          greater_than_or_equal_to: 0, less_than_or_equal_to: Converter::MAX_IP

        if family_col
          validates_inclusion_of family_col,
            in: [Converter::FAMILY_IPV4, Converter::FAMILY_IPV6],
            allow_nil: true,
            message: "must be #{Converter::FAMILY_IPV4} (IPv4) or #{Converter::FAMILY_IPV6} (IPv6)"
        end

        # Reader
        define_method(col) do
          raw = read_attribute_before_type_cast(col)
          return nil if raw.nil?

          fam = family_col ? read_attribute_before_type_cast(family_col) : nil
          Converter.to_ipaddr(raw, family: fam&.to_i)
        rescue RangeError
          nil
        end

        # Writer
        define_method(col_writer) do |addr|
          if addr.nil?
            write_attribute(col, nil)
            write_attribute(family_col, nil) if family_col
            return
          end

          int = Converter.to_integer(addr)
          write_attribute(col, int)

          if family_col && int
            ip = if addr.is_a?(IPAddr)
              addr
            else
              begin
                IPAddr.new(addr.to_s)
              rescue IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
                nil
              end
            end
            write_attribute(family_col, ip ? AddressFamily.from_socket(ip.family) : nil)
          end
        end

        define_method(:"#{col}_display") { public_send(col)&.to_s }
      end
    end
  end
end
