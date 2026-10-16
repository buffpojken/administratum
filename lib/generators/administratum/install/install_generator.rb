# frozen_string_literal: true

require "rails/generators"

module Administratum
  module Generators
    # rails g administratum:install
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      class_option :path, type: :string, default: "/administratum", desc: "Where to mount the admin"

      def copy_initializer
        template "administratum.rb", "config/initializers/administratum.rb"
      end

      def create_admin_directory
        empty_directory "app/admin"
        create_file "app/admin/.keep", ""
      end

      def copy_migrations
        rake "administratum:install:migrations"
      end

      def mount_engine
        route %(mount Administratum::Engine => "#{options[:path]}")
      end

      def show_next_steps
        say <<~TEXT

          Administratum is installed. Next:
            1. bin/rails db:migrate
            2. bin/rails administratum:create_user EMAIL=you@example.com
            3. bin/rails g administratum:resource YourModel
            4. Visit #{options[:path]}
        TEXT
      end
    end
  end
end
