# frozen_string_literal: true

module IpAttribute
  # Base error class for IpAttribute
  class Error < StandardError; end

  # Raised when an IP address cannot be converted
  class ConversionError < Error
    attr_reader :value

    def initialize(value, message = nil)
      @value = value
      super(message || "cannot convert #{value.inspect} to IP address")
    end
  end
end
