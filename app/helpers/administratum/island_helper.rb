# frozen_string_literal: true

module Administratum
  module IslandHelper
    # Renders a mount point for a JS island registered with
    # Administratum.islands.register(name, (el, props) => teardown).
    # Props are serialized as JSON; csrfToken is always included.
    def island(name, props: {}, element: :div, **attributes)
      props = { csrfToken: form_authenticity_token }.merge(props)
      attributes[:data] = (attributes[:data] || {}).merge(administratum_island: name.to_s.dasherize)
      content_tag(element, **attributes) do
        tag.script(ERB::Util.json_escape(props.to_json).html_safe, type: "application/json") # rubocop:disable Rails/OutputSafety
      end
    end
  end
end
