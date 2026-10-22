# frozen_string_literal: true

require "test_helper"

class SearchableSelectTest < ActionDispatch::IntegrationTest
  setup { sign_in_admin }

  test "searchable fields render a combobox select" do
    get administratum.edit_post_path(posts(:hello))
    assert_select "select[name='post[category_id]'][data-adm-combobox][data-adm-combobox-empty='No matches']" do
      assert_select "option[selected]", text: "News"
    end
    assert_select "select[name='post[category_id]'][data-adm-combobox-url]", 0
  end

  test "the stylesheet ships every alert and badge variant" do
    css = File.read(Administratum::Engine.root.join("app/assets/builds/administratum.css"))
    %w[adm-alert-danger adm-alert-warning adm-alert-info adm-badge-success adm-badge-warning adm-badge-danger
       adm-combobox-listbox adm-sortable-handle].each do |name|
      assert_includes css, ".#{name}", "#{name} is missing from the built stylesheet"
    end
  end
end
