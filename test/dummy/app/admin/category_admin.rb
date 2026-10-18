# frozen_string_literal: true

# Uses a custom index template (app/views/admin/categories/index.html.erb).
class CategoryAdmin < Administratum::Resource
  form { field :name }

  show do
    attribute :name
    attribute(:post_count, if: ->(category) { category.posts.any? }) { |category| category.posts.size }
    attribute(:note, if: -> { false }) { "never shown" }
  end
  menu priority: 20
end
