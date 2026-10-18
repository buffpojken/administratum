# frozen_string_literal: true

module Administratum
  # Draws one `resources` block per resource class, nesting children under
  # their parent. Each route points at a controller name that
  # Administratum::Resources resolves back to the resource class.
  module Routing
    module_function

    def draw(router)
      Administratum.registry.reset!
      Administratum.registry.top_level.each { |resource| draw_resource(router, resource) }
      Administratum.registry.pages.each { |page| draw_page(router, page) }
    end

    # GET /<route_key> plus one route per page_action, named <route_key>_page
    # and <action>_<route_key>_page.
    def draw_page(router, page)
      controller = "pages/#{page.controller_id}"
      key = page.route_key
      router.get key, to: "#{controller}#index", as: "#{key}_page"
      page.definition.custom_actions.each_value do |action|
        router.public_send(action.http_method, "#{key}/#{action.name}", to: "#{controller}##{action.name}", as: "#{action.name}_#{key}_page")
      end
    end

    def draw_resource(router, resource, nested: false)
      definition = resource.definition
      options = { controller: "resources/#{resource.controller_id}", only: definition.enabled_actions }
      options[:shallow] = true if nested && definition.parent.shallow

      router.resources(resource.route_key.to_sym, **options) do
        definition.member_actions.each { |action| router.public_send(action.http_method, action.name, on: :member) }
        definition.collection_actions.each { |action| router.public_send(action.http_method, action.name, on: :collection) }
        Administratum.registry.children_of(resource).each { |child| draw_resource(router, child, nested: true) }
      end
    end
  end

  # Rails resolves "administratum/resources/fantasy_admin" to the constant
  # Administratum::Resources::FantasyAdminController. Instead of defining those
  # constants (which would go stale on reload), look the resource up each time.
  module Resources
    def self.const_missing(name)
      id = name.to_s.delete_suffix("Controller").underscore
      Administratum.registry.find_by_controller_id(id) || super
    end
  end

  # The same lookup for "administratum/pages/<controller_id>".
  module Pages
    def self.const_missing(name)
      id = name.to_s.delete_suffix("Controller").underscore
      Administratum.registry.find_page_by_controller_id(id) || super
    end
  end
end
