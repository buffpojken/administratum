# frozen_string_literal: true

require "test_helper"

class ShowAttributesTest < ActionDispatch::IntegrationTest
  setup { sign_in_admin }

  test "if: hides a show attribute, with or without the record" do
    category = categories(:news)
    get administratum.category_path(category)
    assert_select ".adm-attribute dt", text: "Name"
    assert_select ".adm-attribute dt", text: "Post count"
    assert_select ".adm-attribute dt", text: "Note", count: 0

    category.posts.each { |post| post.update!(category: nil) }
    get administratum.category_path(category)
    assert_select ".adm-attribute dt", text: "Post count", count: 0
  end
end
