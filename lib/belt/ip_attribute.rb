#
# Include this module to auto-magically convert IP addresses into decimals.
#

#   include IpAttribute
#
# Adds instance method .to_ip to String, Numeric and including classes.

module IpAttribute
# * TODO: provide machina to disable automagically converting specified attrs
# * TODO: provide machina to specify attrs to be converted automagically
# * TODO: support DataMapper

module ClassMethods
  def install_ip_attribute_hook #:nodoc:

    # IP attributes must be numeric or nil
    # :allow_nil can be overridden validates_presence_of in the calling klass

    self.new.attributes.keys.select{|c|c.match(/^.*_ip$/)}.each {|k|
      validates_numericality_of k.to_sym, :only_integer => true, :allow_nil => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => (2**128)-1
    }

  end
end

def self.included( klass ) #:nodoc:
  klass.extend ClassMethods

  # Only extend non-AR classes
  return unless klass.ancestors.include?(ActiveRecord::Base)

  # ensure there is at least one _ip attribute
  ip_attributes = klass.new.attributes.keys.select{|c|c.match(/^.*_ip$/)}
  ip_methods    = klass.new.methods.select{|c|c.match(/^.*_ip$/)}
  raise(RuntimeError,"unused include - #{klass.class.to_s} does not have any attributes ending in _ip") if ip_attributes.empty? && ip_methods.empty?

  # assign validations and setup to_i conversion
  klass.install_ip_attribute_hook

  ip_attributes.each do |k|

    # typecast the _ip attribute reader
    define_method("#{k}") {
      ip = self.send("#{k}_before_type_cast")
      return if ip.nil?
      begin
        if ip.to_i <= 2**32-1
          ip = IPAddr.new(ip.to_i, Socket::AF_INET)
        else
          ip = IPAddr.new(ip.to_i, Socket::AF_INET6)
        end
      rescue ArgumentError => e
      end
      ip
    }

    # typecast the _ip= attribute writer
    define_method("#{k}=") {|addr|
      begin
        write_attribute(k,self.to_ip(addr))
      rescue ArgumentError => e
        self.errors.add(k)
        raise ActiveRecord::RecordInvalid, self
      end
    }
  end

end

# :call-seq:
#   to_ip(string)
#
# This function converts anything IPAddr can parse into an integer.
#
# == Arguments
# <tt>string</tt>:: Something IPAddr can parse, commonly a string

def to_ip(addr = self)
  if addr.nil?
    ip = nil
  elsif addr.to_s.match(/^\d+$/)
    ip = addr.to_i
  else
    ip = IPAddr.new(addr.to_s).to_i
  end
  ip
end

end

