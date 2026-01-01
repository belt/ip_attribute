# frozen_string_literal: true

require "active_model/type"

module IpAttribute
  # ActiveModel custom type for IP address columns.
  #
  # Handles serialization (IPAddr/String → Integer for DB) and
  # deserialization (Integer → IPAddr for Ruby). Works with both
  # ActiveRecord and plain ActiveModel::Attributes.
  #
  # @example ActiveModel (no database)
  #   class Request
  #     include ActiveModel::Attributes
  #     attribute :client_ip, IpAttribute::Type.new
  #   end
  #
  # @example ActiveRecord (via Railtie auto-registration)
  #   # Registered as :ip_address type automatically
  #   class User < ActiveRecord::Base
  #     attribute :login_ip, :ip_address
  #   end
  #
  class Type < ActiveModel::Type::Value
    # @param normalize_mapped [Boolean] collapse ::ffff:x.x.x.x to IPv4
    def initialize(normalize_mapped: false)
      @normalize_mapped = normalize_mapped
      super()
    end

    def type = :ip_address

    # DB → Ruby: integer to IPAddr
    def deserialize(value)
      return nil if value.nil?

      Converter.to_ipaddr(value.to_i, normalize_mapped: @normalize_mapped)
    rescue RangeError
      nil
    end

    # Ruby → DB: string/IPAddr/integer to integer
    def serialize(value)
      Converter.to_integer(value, normalize_mapped: @normalize_mapped)
    end

    # User input → Ruby: same as serialize (stores integer)
    def cast(value)
      return nil if value.nil?
      return value if value.is_a?(IPAddr)

      int = Converter.to_integer(value, normalize_mapped: @normalize_mapped)
      int ? Converter.to_ipaddr(int) : nil
    rescue RangeError
      nil
    end

    def changed_in_place?(raw_old, new_value)
      raw_old != serialize(new_value)
    end
  end
end
