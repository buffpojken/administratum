# frozen_string_literal: true

# Nested, shallow: collection routes under the post, member routes on their own.
class CommentAdmin < Administratum::Resource
  parent :post, shallow: true
  title :body
  index { column :author; column :body }
  form do
    field :author
    field :body, as: :textarea
  end
end
