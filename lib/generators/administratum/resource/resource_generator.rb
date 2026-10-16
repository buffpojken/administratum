# frozen_string_literal: true

require "rails/generators"

module Administratum
  module Generators
    # rails g administratum:resource Post
    class ResourceGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      SKIPPED_COLUMNS = %w[id created_at updated_at].freeze

      def create_resource_file
        template "resource.rb", File.join("app/admin", class_path, "#{file_name}_admin.rb")
      end

      private

      def model_class
        class_name.safe_constantize
      end

      def field_names
        return [] unless model_class&.table_exists?

        model_class.column_names - SKIPPED_COLUMNS - %w[encrypted_password password_digest]
      end
    end
  end
end
