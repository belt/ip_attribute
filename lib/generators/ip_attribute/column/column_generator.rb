# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record/migration"

module IpAttribute
  module Generators
    # Generates a migration to add IP address columns.
    #
    # @example Single column (Strategy B)
    #   rails generate ip_attribute:column users login_ip
    #
    # @example Single column + family
    #   rails generate ip_attribute:column users login_ip --family
    #
    # @example Dual column (Strategy A)
    #   rails generate ip_attribute:column users client --dual
    #
    class ColumnGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      argument :table_name, type: :string
      argument :column_names, type: :array, default: ["ip"]

      class_option :dual, type: :boolean, default: false,
        desc: "Generate _ipv4 (bigint) + _ipv6 (decimal) column pairs"
      class_option :family, type: :boolean, default: false,
        desc: "Generate _ip_family (smallint) alongside _ip column"

      def create_migration_file
        template_name = options[:dual] ? "add_dual_ip_columns.rb.erb" : "add_ip_columns.rb.erb"
        migration_template(
          template_name,
          "db/migrate/add_#{file_suffix}_to_#{table_name}.rb"
        )
      end

      private

      def prefixes
        @prefixes ||= column_names.map { |c| c.delete_suffix("_ip").delete_suffix("_ipv4").delete_suffix("_ipv6") }
      end

      def normalized_columns
        @normalized_columns ||= column_names.map { |c| c.end_with?("_ip") ? c : "#{c}_ip" }
      end

      def file_suffix
        options[:dual] ? prefixes.join("_and_") + "_ip" : normalized_columns.join("_and_")
      end

      def migration_class_name
        "Add#{file_suffix.camelize}To#{table_name.camelize}"
      end

      def add_family?
        options[:family]
      end
    end
  end
end
