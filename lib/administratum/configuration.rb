# frozen_string_literal: true

module Administratum
  # Global settings, set from config/initializers/administratum.rb.
  class Configuration
    STYLESHEET_MODES = %i[bundled host].freeze

    # Name shown in the top bar and the page title.
    attr_accessor :app_name
    # Path or URL to a logo image. Shown instead of the app name when set.
    attr_accessor :logo
    # Controller the engine's ApplicationController inherits from, as a string.
    attr_accessor :parent_controller
    # Partial rendered on the dashboard. nil renders the built-in resource overview.
    attr_accessor :dashboard
    # Sender address for password reset emails.
    attr_accessor :mailer_sender
    # Default page size on index pages.
    attr_accessor :per_page
    # Whether Administratum::UserAdmin is mounted, so admins can manage admin users.
    attr_accessor :manage_users
    # A lambda receiving the view context, returning extra tags for <head>.
    attr_accessor :head
    # A partial rendered inside <head>, alternative to `head`.
    attr_accessor :head_partial
    # Extra helper modules made available in every admin view.
    attr_accessor :helpers
    # Directories scanned for resource definitions, relative to Rails.root.
    attr_accessor :resource_paths
    # Token overrides, e.g. { primary: "#7c3aed" } becomes --color-adm-primary.
    attr_reader :theme, :dark_theme
    attr_reader :stylesheet, :field_types

    def initialize
      @app_name = "Administratum"
      @parent_controller = "ActionController::Base"
      @mailer_sender = "admin@example.com"
      @per_page = 25
      @manage_users = true
      @helpers = []
      @resource_paths = ["app/admin"]
      @theme = {}
      @dark_theme = {}
      @stylesheet = :bundled
      @field_types = FieldTypes.new
    end

    def theme=(tokens)
      @theme = tokens.to_h
    end

    def dark_theme=(tokens)
      @dark_theme = tokens.to_h
    end

    def stylesheet=(mode)
      mode = mode.to_sym
      raise ArgumentError, "stylesheet must be one of #{STYLESHEET_MODES.join(', ')}" unless STYLESHEET_MODES.include?(mode)

      @stylesheet = mode
    end
  end
end
