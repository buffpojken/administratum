# frozen_string_literal: true

# A custom page: default index with a _content partial, a POST action behind a
# header button, and a GET action with its own template.
class ReportsPage < Administratum::Page
  menu priority: 5
  page_action :refresh, method: :post
  page_action :weekly

  button :refresh, confirm: "Refresh the report?", style: :primary
  button :weekly

  def index
    @post_count = Post.count
  end

  def refresh
    redirect_to page_path, notice: "Report refreshed"
  end
end
