# frozen_string_literal: true

module Administratum
  module LayoutHelper
    def administratum_config
      Administratum.config
    end

    def administratum_title
      [content_for(:title).presence, administratum_config.app_name].compact.join(" · ")
    end

    def administratum_stylesheet_tag
      stylesheet_link_tag("administratum") if administratum_config.stylesheet == :bundled
    end

    # Token overrides from config.theme / config.dark_theme as CSS variables.
    def administratum_theme_style
      light = theme_declarations(administratum_config.theme)
      dark = theme_declarations(administratum_config.dark_theme)
      return if light.empty? && dark.empty?

      css = +""
      css << ":root{#{light}}" if light.present?
      css << ":root.dark{#{dark}}@media (prefers-color-scheme: dark){:root:not(.light){#{dark}}}" if dark.present?
      tag.style(css.html_safe, nonce: content_security_policy_nonce) # rubocop:disable Rails/OutputSafety
    end

    # Puts .dark or .light on <html> before first paint: the stored choice, else
    # the OS preference. Always setting a class gives host CSS a reliable
    # `.dark` hook (Tailwind's class-based dark variant, editor styles…).
    def administratum_color_scheme_script
      javascript_tag(<<~JS, nonce: true)
        (function(){var m=null;try{m=localStorage.getItem("administratum-theme")}catch(e){}if(m!=="dark"&&m!=="light"){m=window.matchMedia("(prefers-color-scheme: dark)").matches?"dark":"light"}document.documentElement.classList.add(m)})();
      JS
    end

    def administratum_head
      safe_join([
        administratum_config.head&.call(self),
        (render(administratum_config.head_partial) if administratum_config.head_partial)
      ].compact)
    end

    def administratum_nav_items
      Administratum.registry.menu_items.map do |resource|
        { label: resource.menu_label, path: Administratum::Paths.new(resource, self).index, active: nav_active?(resource) }
      end
    end

    # Renders the page header: breadcrumbs, title and the block's buttons.
    def page_header(title:, breadcrumbs: nil, &block)
      content_for(:title, title)
      render "administratum/shared/page_header", title:, breadcrumbs: breadcrumbs || default_breadcrumbs,
                                                 actions: block ? capture(&block) : nil
    end

    def card(title: nil, footer: nil, flush: false, &)
      render "administratum/shared/card", title:, footer:, flush:, body: capture(&)
    end

    private

    def nav_active?(resource)
      return false unless controller.is_a?(Administratum::Resource)

      current = controller.class
      current = current.parent_resource while current.definition.parent && current.parent_resource && current != resource
      current == resource
    end

    def theme_declarations(tokens)
      tokens.map do |key, value|
        name = key.to_s.start_with?("--") ? key.to_s : "--color-adm-#{key.to_s.dasherize}"
        "#{name.gsub(/[^a-z0-9-]/i, '')}:#{value.to_s.gsub(/[;{}<>]/, '')};"
      end.join
    end
  end
end
