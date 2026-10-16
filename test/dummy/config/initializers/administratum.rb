# frozen_string_literal: true

Administratum.configure do |config|
  config.app_name = "Dummy Admin"
  config.head = ->(view) { view.javascript_include_tag("dummy_admin", type: "module") }
  config.field_types.register :color, partial: "admin/fields/color"
end
