# frozen_string_literal: true

# Plain CRUD plus a custom write page with a JS island, export/import and buttons.
class PostAdmin < Administratum::Resource
  filters :title, :published, :category_id
  index csv: true, sort: "created_at desc" do
    column :title
    column :category
    column :published
    column(:comments, sortable: false) { |post| post.comments.size }
  end

  form do
    field :title, hint: "Shown in listings", placeholder: "A catchy headline"
    field :body, as: :textarea, rows: 6
    field :published
    field :category_id, placeholder: "Pick a category"
    field :tag_ids
    field :color, as: :color
    field :metadata, as: :json
  end

  member_action :write
  member_action :save_body, method: :patch
  member_action :publish, method: :post
  collection_action :export
  collection_action :import, method: :post

  button :write, on: %i[show row], style: :primary
  button :publish, on: :show, confirm: "Publish this post?", if: ->(post) { !post.published? }
  button :comments, on: :show, to: ->(post) { post_comments_path(post) }
  button :export, on: :index
  button :import, on: :index, upload: ".json"

  menu priority: 10

  def save_body
    @resource.update!(body: params.require(:body))
    render json: { body: @resource.body }
  end

  def publish
    @resource.update!(published: true)
    redirect_to resource_path, notice: "Published"
  end

  def export
    send_data Post.export_json, filename: "posts.json", type: :json
  end

  def import
    count = Post.import_json(params.require(:file).read)
    redirect_to collection_path, notice: "Imported #{count}"
  end
end
