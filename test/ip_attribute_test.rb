require File.dirname(__FILE__) + '/test_helper'
require 'lib/ar_extensions'

class IpAttributeTest < ActiveSupport::TestCase
  def test_to_ip
    require 'ipaddr'
    assert_equal nil, 'wuff'.to_ip
    assert_equal 3232235532, '192.168.0.12'.to_ip
    assert_equal 2130706433, '127.0.0.1'.to_ip
    assert_equal 2130706433, '::7F00:1'.to_ip
    assert_equal 2**32-1, '255.255.255.255'.to_ip
    assert_equal 2**32-1, '::FFFF:FFFF'.to_ip
    assert_equal 2**32, '::1:0:0'.to_ip
    assert_equal IPAddr.new('127.0.0.1').to_i, '127.0.0.1'.to_ip
    assert_equal 85060308944708794891899627827609206785, '3FFE:505:2::1'.to_ip
  rescue LoadError
    puts "\n>> Could not load IPAddr. String#to_ip was not tested.\n>> Please gem install IPAddr if you'd like to use this functionality."
  end
end

