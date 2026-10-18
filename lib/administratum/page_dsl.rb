# frozen_string_literal: true

module Administratum
  # Class-level DSL for custom pages (Administratum::Page subclasses in app/admin).
  module PageDSL
    include DSL::Common

    def definition
      @definition ||= superclass.respond_to?(:definition) ? superclass.definition.dup : Definition.new
    end

    # Marks a class as a base for other pages: it gets no route or menu entry.
    def abstract_page!
      @abstract_page = true
    end

    def abstract_page?
      @abstract_page == true || name == "Administratum::Page"
    end

    def label(text)
      definition.label = text
    end

    # An extra route on the page, /<route_key>/<name>, handled by the method of that name.
    def page_action(name, method: :get)
      definition.add_action(name, http_method: method, scope: :collection)
    end

    # Buttons on a page default to its header.
    def button(name, on: :page, **)
      super
    end

    # ReportsPage => "reports"; Stats::WeeklyPage => "stats_weekly".
    def route_key
      definition.route_key || name.delete_suffix("Page").underscore.tr("/", "_")
    end

    def page_title
      definition.label || route_key.humanize
    end

    def menu_label
      definition.menu.label || page_title
    end
  end
end
