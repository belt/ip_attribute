# frozen_string_literal: true

require "active_support/concern"
require_relative "ip_helpers"
require_relative "strategy_dual"
require_relative "strategy_single"

module IpAttribute
  # ActiveRecord integration for automatic IP attribute handling.
  #
  # Auto-detects storage strategy from column naming convention.
  # See StrategyDual and StrategySingle for implementation details.
  #
  module ActiveRecordIntegration
    extend ActiveSupport::Concern

    # Column config for Strategy B (eliminates DataClump).
    SingleConfig = Data.define(:col, :family_col)

    included do
      include IpAttribute::IpHelpers
      extend IpAttribute::QueryMethods

      columns = column_names
      dual_prefixes = _detect_dual_prefixes(columns)
      single_cols = columns.grep(/_ip\z/)

      if dual_prefixes.empty? && single_cols.empty?
        raise IpAttribute::Error,
          "#{name} has no IP columns — need _ip, or _ipv4/_ipv6 pairs"
      end

      dual_prefixes.each { |prefix| _install_dual(prefix) }

      dual_names = dual_prefixes.flat_map { |pfx| ["#{pfx}_ipv4", "#{pfx}_ipv6"] }
      single_cols.reject { |col| dual_names.include?(col) }.each do |col|
        family_col = "#{col}_family"
        cfg = SingleConfig.new(col: col, family_col: columns.include?(family_col) ? family_col : nil)
        _install_single(cfg)
      end
    end

    class_methods do
      include IpAttribute::StrategyDual
      include IpAttribute::StrategySingle

      def _detect_dual_prefixes(columns)
        ipv4_prefixes = columns.grep(/_ipv4\z/).map { |col| col.delete_suffix("_ipv4") }
        ipv6_prefixes = columns.grep(/_ipv6\z/).map { |col| col.delete_suffix("_ipv6") }
        (ipv4_prefixes & ipv6_prefixes).freeze
      end

      # Shared reader factory for both strategies.
      def _define_ip_reader(col, family:)
        define_method(col) do
          raw = read_attribute_before_type_cast(col)
          raw ? Converter.to_ipaddr(raw, family: family) : nil
        rescue RangeError
          nil
        end
      end
    end
  end
end
