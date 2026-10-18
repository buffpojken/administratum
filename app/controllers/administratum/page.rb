# frozen_string_literal: true

module Administratum
  # Base class for custom pages declared in app/admin: a controller with a
  # menu entry and its own route, for reports, tools and anything that isn't
  # CRUD on one model. Templates are looked up in app/views/admin/<route_key>
  # first; the default index renders the page header and a `_content` partial.
  class Page < ApplicationController
    extend Administratum::PageDSL

    helper_method :definition, :page_class, :page_path, :action_path

    def index; end

    # Same as Resource: point host-defined pages at the engine's url helpers.
    def self.inherited(subclass)
      super
      subclass.include(Administratum::Engine.routes.url_helpers)
      subclass.include(Administratum::Engine.routes.mounted_helpers)
    end

    def self.controller_path
      name.nil? || abstract_page? ? super : "administratum/pages/#{controller_id}"
    end

    private

    def _prefixes
      @_prefixes ||= ["#{Administratum.config.view_prefix}/#{page_class.route_key}", "administratum/pages"]
    end

    def page_class
      self.class
    end

    def definition
      page_class.definition
    end

    def page_path(**)
      public_send(:"#{page_class.route_key}_page_path", **)
    end

    # Path for a page_action. The second argument keeps the signature buttons use for resources.
    def action_path(name, _record = nil, **)
      definition.custom_actions.fetch(name.to_sym)
      public_send(:"#{name}_#{page_class.route_key}_page_path", **)
    end
  end
end
