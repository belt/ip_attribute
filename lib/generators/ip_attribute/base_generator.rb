# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record/migration"

module IpAttribute
  module Generators
    # Shared logic for column and index generators.
    class BaseGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      argument :table_name, type: :string
      argument :column_names, type: :array, default: ["ip"]

      class_option :dual, type: :boolean, default: false,
        desc: "Use _ipv4/_ipv6 column pairs"

      private

      def prefixes
        @prefixes ||= column_names.map { |name| name.delete_suffix("_ip").delete_suffix("_ipv4").delete_suffix("_ipv6") }
      end

      def normalized_columns
        @normalized_columns ||= column_names.map { |name| name.end_with?("_ip") ? name : "#{name}_ip" }
      end

      def file_suffix
        options[:dual] ? prefixes.join("_and_") + "_ip" : normalized_columns.join("_and_")
      end
    end
  end
end
