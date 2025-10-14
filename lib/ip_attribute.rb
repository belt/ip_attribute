# frozen_string_literal: true

require "ipaddr"
require "socket"

require_relative "ip_attribute/version"
require_relative "ip_attribute/error"
require_relative "ip_attribute/address_family"
require_relative "ip_attribute/converter"

# IpAttribute — ActiveRecord IP address attribute handling.
#
# Converts IP address columns (ending in `_ip`) between human-readable
# strings and integer storage. Supports IPv4 and IPv6.
#
# @example ActiveRecord integration
#   class User < ActiveRecord::Base
#     include IpAttribute::ActiveRecordIntegration
#   end
#
# @example Standalone converter
#   IpAttribute::Converter.to_integer("127.0.0.1")  # => 2130706433
#   IpAttribute::Converter.to_ipaddr(2130706433)     # => #<IPAddr: IPv4:127.0.0.1/...>
#
# @example Opt-in refinements
#   require "ip_attribute/core_ext"
#   using IpAttribute::CoreExt
#   "192.168.0.1".to_ip  # => 3232235521
#
module IpAttribute
  # Load on demand (avoids hard AR dependency at require time)
  autoload :ActiveRecordIntegration, "ip_attribute/active_record_integration"
  autoload :CoreExt, "ip_attribute/core_ext"
  autoload :QueryMethods, "ip_attribute/query_methods"
  autoload :Type, "ip_attribute/type"
end

# Load Rails integration when Rails is present
require_relative "ip_attribute/railtie" if defined?(Rails::Railtie)
