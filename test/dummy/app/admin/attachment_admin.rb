# frozen_string_literal: true

# Nested, not shallow: every route goes through the post.
class AttachmentAdmin < Administratum::Resource
  parent :post
  actions except: :show
  form { field :name }
end
