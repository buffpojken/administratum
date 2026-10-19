# frozen_string_literal: true

require "test_helper"

class CrudTest < ActionDispatch::IntegrationTest
  setup { sign_in_admin }

  test "dashboard lists menu resources" do
    get administratum.root_path
    assert_response :success
    assert_select ".adm-nav-link", text: "Posts"
    assert_select ".adm-nav-link", text: "Tags", count: 0
  end

  test "index renders columns, row buttons and custom buttons" do
    get administratum.posts_path
    assert_response :success
    assert_select "th", text: "Title"
    assert_select "td", text: "Hello world"
    assert_select "a[href=?]", administratum.write_post_path(posts(:hello)), text: "Write"
    assert_select "a[href=?]", administratum.export_posts_path, text: "Export"
    assert_select "[data-adm-offcanvas-open=adm-filters]"
  end

  test "index filters through ransack without a model allowlist" do
    get administratum.posts_path, params: { q: { title_cont: "Draft" } }
    assert_select "td", text: "Draft thoughts"
    assert_select "td", text: "Hello world", count: 0

    get administratum.posts_path, params: { q: { published_eq: "true" } }
    assert_select "td", text: "Hello world", count: 0
  end

  test "index sorts" do
    get administratum.posts_path, params: { q: { s: "title asc" } }
    assert_match(/Draft thoughts.*Hello world/m, response.body)
  end

  test "index exports csv" do
    get administratum.posts_path(format: :csv)
    assert_equal "text/csv", response.media_type
    assert_includes response.body, "Hello world"
  end

  test "csv exports block columns as text and skips csv: false columns" do
    get administratum.posts_path(format: :csv)
    rows = CSV.parse(response.body, headers: true)
    assert_equal %w[Title Category Published Comments Summary], rows.headers
    hello = rows.find { |row| row["Title"] == "Hello world" }
    assert_equal "1", hello["Comments"]
    assert_equal "First post", hello["Summary"]
    assert_equal categories(:news).name, hello["Category"]
  end

  test "creates with permitted params only" do
    assert_difference("Post.count") do
      post administratum.posts_path, params: { post: { title: "New", published: "1", tag_ids: [tags(:ruby).id], id: 999 } }
    end
    created = Post.order(:id).last
    assert_redirected_to administratum.post_path(created)
    assert created.published
    assert_equal [tags(:ruby)], created.tags
    assert_not_equal 999, created.id
  end

  test "re-renders new with errors" do
    post administratum.posts_path, params: { post: { title: "" } }
    assert_response :unprocessable_content
    assert_select ".adm-error", /can't be blank/
  end

  test "new form renders built-in and custom field types" do
    get administratum.new_post_path
    assert_select "textarea[name='post[body]'][rows='6']"
    assert_select "input[type=checkbox][name='post[published]']"
    assert_select "select[name='post[category_id]'] option", text: "News"
    assert_select "select[multiple][name='post[tag_ids][]']"
    assert_select "input.color-field[name='post[color]']"
    assert_select "textarea[name='post[metadata]']"
    assert_select ".adm-hint", "Shown in listings"
  end

  test "fields take placeholders, hints and required markers" do
    get administratum.new_post_path
    assert_select "input[name='post[title]'][placeholder='A catchy headline'][aria-describedby=post_title_hint]"
    assert_select "#post_title_hint", "Shown in listings"
    assert_select "select[name='post[category_id]'] option[value='']", "Pick a category"
    assert_select "label[for=post_title] .adm-required"
    assert_select "label[for=post_body] .adm-required", count: 0
    assert_select "label[for=post_tag_ids]", "Tags"
  end

  test "updates" do
    patch administratum.post_path(posts(:hello)), params: { post: { title: "Changed" } }
    assert_redirected_to administratum.post_path(posts(:hello))
    assert_equal "Changed", posts(:hello).reload.title
  end

  test "shows" do
    get administratum.post_path(posts(:hello))
    assert_response :success
    assert_select "h1", "Hello world"
    assert_select "dd", text: "First post"
  end

  test "destroys" do
    assert_difference("Post.count", -1) { delete administratum.post_path(posts(:draft)) }
    assert_redirected_to administratum.posts_path
  end

  test "built-in admin user management keeps the password when left blank" do
    user = administratum_users(:admin)
    patch administratum.admin_user_path(user), params: { user: { email: "boss@example.com", password: "" } }
    assert_redirected_to administratum.admin_user_path(user)
    assert user.reload.valid_password?("password123")
  end
end
