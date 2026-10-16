# frozen_string_literal: true

# Hidden from the menu, with a custom form template.
class TagAdmin < Administratum::Resource
  form { field :name }
  menu false
end
