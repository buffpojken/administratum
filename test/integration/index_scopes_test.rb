# frozen_string_literal: true

require "test_helper"

class IndexScopesTest < ActionDispatch::IntegrationTest
  setup { sign_in_admin }

  test "renders a tab per scope with counts, the first one active" do
    get administratum.posts_path
    assert_select ".adm-tab", count: 3
    assert_select ".adm-tab-active[aria-current=page]", text: /All/
    assert_select ".adm-tab", text: "All2"
    assert_select ".adm-tab", text: "Published1"
    assert_select ".adm-tab", text: "Drafts"
    assert_select ".adm-tab .adm-tab-count", count: 2
  end

  test "a block scope narrows the index" do
    get administratum.posts_path, params: { scope: "live" }
    assert_select ".adm-tab-active", text: /Published/
    assert_select "td", text: "Draft thoughts"
    assert_select "td", text: "Hello world", count: 0
  end

  test "a scope without a block calls the model scope" do
    get administratum.posts_path, params: { scope: "drafts" }
    assert_select "td", text: "Hello world"
    assert_select "td", text: "Draft thoughts", count: 0
  end

  test "an unknown scope falls back to the default" do
    get administratum.posts_path, params: { scope: "nope" }
    assert_select ".adm-tab-active", text: /All/
    assert_select "td", text: "Hello world"
  end

  test "default: true picks the default tab" do
    PostAdmin.definition.index_scopes.find { |s| s.name == :live }.default = true
    get administratum.posts_path
    assert_select ".adm-tab-active", text: /Published/
  ensure
    PostAdmin.definition.index_scopes.find { |s| s.name == :live }.default = false
  end

  test "tabs keep filters and counts respect them; filters keep the tab" do
    get administratum.posts_path, params: { scope: "live", q: { title_cont: "Hello" }, page: 1 }
    assert_select ".adm-tab", text: "All1"
    assert_select ".adm-tab", text: "Published0"
    link = css_select(".adm-tab").find { |a| a.text.start_with?("All") }["href"]
    assert_includes link, "q%5Btitle_cont%5D=Hello"
    assert_not_includes link, "page="
    assert_select "form.adm-form input[type=hidden][name=scope][value=live]"
  end

  test "csv export respects the tab" do
    get administratum.posts_path(format: :csv, scope: "drafts")
    assert_includes response.body, "Hello world"
    assert_not_includes response.body, "Draft thoughts"
  end

  test "resources without scopes render no tabs" do
    get administratum.categories_path
    assert_select ".adm-tabs", count: 0
  end
end
