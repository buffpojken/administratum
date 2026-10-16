# frozen_string_literal: true

# Uses a custom index template (app/views/admin/categories/index.html.erb).
class CategoryAdmin < Administratum::Resource
  form { field :name }
  menu priority: 20
end
