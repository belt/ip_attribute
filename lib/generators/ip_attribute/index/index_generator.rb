# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record/migration"

module IpAttribute
  module Generators
    # Generates a migration to add indexes to existing IP columns.
    # Uses algorithm: :concurrently for zero-downtime on PostgreSQL.
    #
    # @example
    #   rails generate ip_attribute:index users login_ip
    #   rails generate ip_attribute:index sessions client --dual
    #
    class IndexGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      argument :table_name, type: :string
      argument :column_names, type: :array, default: ["ip"]

      class_option :dual, type: :boolean, default: false,
        desc: "Index _ipv4/_ipv6 column pairs"

      def create_migration_file
        template_name = options[:dual] ? "index_dual_ip_columns.rb.erb" : "index_ip_columns.rb.erb"
        migration_template(
          template_name,
          "db/migrate/index_#{file_suffix}_on_#{table_name}.rb"
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
        "Index#{file_suffix.camelize}On#{table_name.camelize}"
      end
    end
  end
end
