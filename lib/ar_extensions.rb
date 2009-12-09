# IpAttribute
#
# Include this module to auto-magically convert IP addresses into decimals.
#

require File.join('belt','ip_attribute')

# support .to_ip in strings and numbers
String.send :include, IpAttribute
Numeric.send :include, IpAttribute

