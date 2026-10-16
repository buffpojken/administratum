# frozen_string_literal: true

require "test_helper"

class TemplatesTest < ActionDispatch::IntegrationTest
  setup { sign_in_admin }

  test "app template overrides the default index" do
    get administratum.categories_path
    assert_select "#category-tiles a", text: "News"
    assert_select "table", count: 0
  end

  test "app partial overrides the default form" do
    get administratum.new_tag_path
    assert_select "#custom-tag-form form[action=?]", administratum.tags_path
    assert_select "input[name='tag[name]']"
  end

  test "view prefix is configurable" do
    Administratum.config.view_prefix = "elsewhere"
    get administratum.categories_path
    assert_select "table"
    assert_select "#category-tiles", count: 0
  ensure
    Administratum.config.view_prefix = "admin"
  end

  test "pages load the bundled stylesheet, runtime and host head" do
    get administratum.posts_path
    assert_select "link[rel=stylesheet][href*=administratum]"
    assert_select "script[type=module][src*=administratum]"
    assert_select "script[type=module][src*=dummy_admin]"
  end

  test "the color scheme script always sets a theme class" do
    get administratum.posts_path
    assert_includes response.body, 'prefers-color-scheme: dark)").matches?"dark":"light"'
  end

  test "theme overrides render as css variables" do
    Administratum.config.theme = { primary: "#7c3aed" }
    get administratum.posts_path
    assert_includes response.body, "--color-adm-primary:#7c3aed;"
  ensure
    Administratum.config.theme = {}
  end
end
