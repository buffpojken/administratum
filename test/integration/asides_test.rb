# frozen_string_literal: true

require "test_helper"

class AsidesTest < ActionDispatch::IntegrationTest
  setup { sign_in_admin }

  test "aside buttons render as a menu beside the show page, not in the header" do
    get administratum.post_path(posts(:draft))
    assert_select ".adm-with-aside .adm-aside nav.adm-card[aria-label=Maintenance]" do
      assert_select ".adm-card-title", "Maintenance"
      assert_select "a.adm-menu-item[href=?]", administratum.post_comments_path(posts(:draft)), text: "All comments"
      assert_select "form.adm-menu-form[action=?][data-adm-confirm='Unpublish this post?'] button.adm-menu-item-danger",
                    administratum.unpublish_post_path(posts(:draft)), text: "Unpublish"
    end
    assert_select ".adm-page-actions form[action=?]", administratum.unpublish_post_path(posts(:draft)), count: 0
  end

  test "an aside whose buttons are all hidden leaves the page unwrapped" do
    buttons = PostAdmin.definition.asides_for(:show).first.buttons
    conditions = buttons.map(&:condition)
    buttons.each { |button| button.condition = -> { false } }
    get administratum.post_path(posts(:hello))
    assert_select ".adm-with-aside", count: 0
    assert_select ".adm-attributes"
  ensure
    buttons.zip(conditions) { |button, condition| button.condition = condition }
  end

  test "if: hides single aside buttons" do
    get administratum.post_path(posts(:hello))
    assert_select ".adm-aside form[action=?]", administratum.unpublish_post_path(posts(:hello)), count: 0
    assert_select ".adm-aside a", text: "All comments"
  end

  test "index aside defaults its title and points at collection actions" do
    get administratum.posts_path
    assert_select ".adm-aside nav[aria-label=Actions] a.adm-menu-item[href=?]", administratum.export_posts_path,
                  text: "Export JSON"
  end

  test "pages without asides are unchanged" do
    get administratum.edit_post_path(posts(:draft))
    assert_select ".adm-with-aside", count: 0
  end

  test "aside menu actions run" do
    post administratum.unpublish_post_path(posts(:draft))
    assert_redirected_to administratum.post_path(posts(:draft))
    assert_not posts(:draft).reload.published
  end
end
