# frozen_string_literal: true

Administratum.configure do |config|
  # Shown in the top bar and the browser title.
  config.app_name = "<%= Rails.application.class.module_parent_name.titleize %> Admin"

  # config.logo = "admin/logo.svg"
  # config.mailer_sender = "admin@example.com"
  # config.per_page = 25

  # Controller the admin inherits from. Use it for app-wide before_actions.
  # config.parent_controller = "ActionController::Base"

  # Partial rendered on the dashboard instead of the resource overview.
  # config.dashboard = "admin/dashboard"

  # Load your own JS (islands, Turbo, Stimulus…) and CSS into the admin <head>.
  # config.head = ->(view) { view.javascript_importmap_tags("admin") }
  # config.head = ->(view) { view.vite_javascript_tag("admin") }
  # config.head_partial = "admin/head"

  # Colour tokens (--color-adm-*). Applied on top of the bundled stylesheet.
  # config.theme = { primary: "#7c3aed" }
  # config.dark_theme = { primary: "#a78bfa" }

  # :bundled uses the stylesheet shipped with the gem; :host means your
  # Tailwind v4 build includes Administratum (see bin/rails administratum:tailwind:sync).
  # config.stylesheet = :bundled

  # Custom field types: a partial that receives form:, field:, resource:, value:.
  # config.field_types.register :tags, partial: "admin/fields/tags"

  # Extra helper modules for admin views.
  # config.helpers = [ApplicationHelper]

  # Set to false to hide admin user management.
  # config.manage_users = true
end
