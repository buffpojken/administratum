# frozen_string_literal: true

module Administratum
  class Engine < ::Rails::Engine
    isolate_namespace Administratum

    initializer "administratum.devise" do
      require "devise/orm/active_record"
    end

    # Redraw routes when a resource file changes, since routes are derived
    # from the resource definitions.
    initializer "administratum.reloading" do |app|
      checker = nil

      config.after_initialize do
        dirs = Administratum.registry.resource_dirs.index_with { ["rb"] }
        checker = ActiveSupport::FileUpdateChecker.new([], dirs) { nil }
        app.reloaders << checker
      end

      config.to_prepare do
        Administratum.registry.reset!
        if checker&.updated?
          checker.execute
          app.reload_routes!
        end
      end
    end
  end
end
