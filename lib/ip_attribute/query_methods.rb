# frozen_string_literal: true

module IpAttribute
  # Query helper for IP subnet range lookups.
  #
  # @example
  #   class User < ActiveRecord::Base
  #     include IpAttribute::ActiveRecordIntegration
  #   end
  #
  #   User.where_ip(:login_ip, "192.168.0.0/24")
  #   User.where_ip(:login_ip, "10.0.0.0/8")
  #   User.where_ip(:login_ip, "::ffff:0:0/96")
  #
  module QueryMethods
    # Query records whose IP column falls within a subnet.
    #
    # @param column [Symbol] the _ip column name
    # @param cidr [String] CIDR notation (e.g., "192.168.0.0/24")
    # @return [ActiveRecord::Relation]
    def where_ip(column, cidr)
      network = IPAddr.new(cidr)
      range = network.to_range
      where(column => range.first.to_i..range.last.to_i)
    end
  end
end
