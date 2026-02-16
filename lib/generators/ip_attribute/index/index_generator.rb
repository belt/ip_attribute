# frozen_string_literal: true

require_relative "../base_generator"

module IpAttribute
  module Generators
    # Generates a migration to add indexes to existing IP columns.
    #
    # @example
    #   rails generate ip_attribute:index users login_ip
    #   rails generate ip_attribute:index sessions client --dual
    #
    class IndexGenerator < BaseGenerator
      source_root File.expand_path("templates", __dir__)

      def create_migration_file
        template_name = options[:dual] ? "index_dual_ip_columns.rb.erb" : "index_ip_columns.rb.erb"
        migration_template(template_name, "db/migrate/index_#{file_suffix}_on_#{table_name}.rb")
      end

      private

      def migration_class_name
        "Index#{file_suffix.camelize}On#{table_name.camelize}"
      end
    end
  end
end
