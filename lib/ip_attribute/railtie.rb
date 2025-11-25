# frozen_string_literal: true

require "rails/railtie"

module IpAttribute
  # Rails integration: registers the :ip_address type with ActiveRecord.
  #
  # Auto-loaded when Rails is present. No manual configuration needed.
  #
  class Railtie < Rails::Railtie
    initializer "ip_attribute.register_type" do
      ActiveSupport.on_load(:active_record) do
        require "ip_attribute/type"
        ActiveRecord::Type.register(:ip_address, IpAttribute::Type)
      end
    end
  end
end
