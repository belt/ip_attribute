# frozen_string_literal: true

require_relative "../base_generator"

module IpAttribute
  module Generators
    # Generates a migration to add IP address columns + indexes.
    #
    # @example
    #   rails generate ip_attribute:column users login_ip
    #   rails generate ip_attribute:column users login_ip --family
    #   rails generate ip_attribute:column sessions client --dual
    #
    class ColumnGenerator < BaseGenerator
      source_root File.expand_path("templates", __dir__)

      class_option :family, type: :boolean, default: false,
        desc: "Generate _ip_family (tinyint) alongside _ip column"

      def create_migration_file
        template_name = options[:dual] ? "add_dual_ip_columns.rb.erb" : "add_ip_columns.rb.erb"
        migration_template(template_name, "db/migrate/add_#{file_suffix}_to_#{table_name}.rb")
      end

      private

      def migration_class_name
        "Add#{file_suffix.camelize}To#{table_name.camelize}"
      end

      def add_family?
        options[:family]
      end
    end
  end
end
