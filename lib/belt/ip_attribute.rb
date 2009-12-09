#
# Include this module to auto-magically convert IP addresses into decimals.
#

module IpAttribute
module ClassMethods
  def install_ip_attribute_hook
    before_validation :set_ip

    # IP attributes must be numeric or nil
    # Override the allow_nil with validates_presence_of in the calling klass
    self.new.attributes.keys.select{|c|c.match(/^.*_ip$/)}.each {|k|
      validates_numericality_of k.to_sym, :only_integer => true, :allow_nil => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => (2**128)-1
    }

  end
end

def self.included( klass )
  klass.extend ClassMethods
  return unless klass.ancestors.include?(ActiveRecord::Base)

  ip_attributes = klass.new.attributes.keys.select{|c|c.match(/^.*_ip$/)}
  ip_methods    = klass.new.methods.select{|c|c.match(/^.*_ip$/)}

  raise(RuntimeError,"unused include - #{klass.class.to_s} does not have any attributes ending in _ip") if ip_attributes.empty? && ip_methods.empty?

  klass.install_ip_attribute_hook
  ip_attributes.each do |k|

    # type cast the _ip= attribute reader
    define_method("#{k}") {
      ip = self.send("#{k}_before_type_cast")
      return if ip.nil?
      if ip.to_i <= 2**32-1
        ip = IPAddr.new(ip.to_i, Socket::AF_INET)
      else
        ip = IPAddr.new(ip.to_i, Socket::AF_INET6)
      end
      ip
    }

    # type cast the _ip= attribute writer
    define_method("#{k}=") {|addr|
      self[k] = self.to_ip(addr)
    }
  end

end

def set_ip
  ip_attributes = self.class.new.attributes.keys.select{|c|c.match(/^.*_ip$/)}
  ip_attributes.each do |k|
      self[k] = self.class.to_ip(self.send(k))
  end
end

# :call-seq:
#   to_ip(string)
#
# This function converts anything IPAddr can parse into an integer.
#
# == Arguments
# <tt>string</tt>:: A string

def to_ip(addr = self)
  if addr.nil?
    ip = nil
  elsif addr.to_s.match(/^\d+$/)
    ip = addr.to_i
  else
    begin
      ip = IPAddr.new(addr.to_s).to_i
    rescue ArgumentError
      ip = nil
    end
  end
  ip
end

end

