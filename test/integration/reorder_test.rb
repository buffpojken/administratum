# frozen_string_literal: true

require "test_helper"

class ReorderTest < ActionDispatch::IntegrationTest
  setup { sign_in_admin }

  test "index sorted by position shows reorder controls that work without JS" do
    get administratum.post_comments_path(posts(:hello))
    assert_response :success
    assert_select "form#adm-reorder[action=?]", administratum.reorder_post_comments_path(posts(:hello)) do
      assert_select "input[name=_method][value=patch]"
    end
    assert_select "tbody[data-adm-sortable] tr[data-adm-sortable-item]", 3
    assert_select "input[name=?][value='1'][form=adm-reorder]", "positions[#{comments(:first).id}]"
    assert_select "button[data-adm-sortable-handle][hidden]"
    assert_select "button[type=submit][form=adm-reorder]", text: "Save order"
    assert_equal ["Nice post", "Agreed", "Ship it"], css_select("tbody tr td:nth-child(3)").map { |td| td.text.strip }
  end

  test "controls are left out when the list is sorted by something else" do
    get administratum.post_comments_path(posts(:hello), q: { s: "author desc" })
    assert_select "[data-adm-sortable]", 0
    assert_select "form#adm-reorder", 0
  end

  test "reorder renumbers the parent's records only" do
    patch administratum.reorder_post_comments_path(posts(:hello)),
          params: { positions: { comments(:third).id => 1, comments(:first).id => 2, comments(:second).id => 2,
                                 comments(:elsewhere).id => 9 } },
          headers: { "HTTP_REFERER" => administratum.post_comments_path(posts(:hello)) }

    assert_redirected_to administratum.post_comments_path(posts(:hello))
    assert_equal "Comments were reordered.", flash[:notice]
    assert_equal %w[Ship\ it Nice\ post Agreed], posts(:hello).comments.order(:position).pluck(:body)
    assert_equal [1, 2, 3], posts(:hello).comments.order(:position).pluck(:position)
    assert_equal 1, comments(:elsewhere).reload.position
  end

  test "reorder keeps records left out of the payload in place, and answers JSON" do
    patch administratum.reorder_post_comments_path(posts(:hello)), params: { positions: { comments(:first).id => 3 } }, as: :json
    assert_response :no_content
    assert_equal %w[Agreed Ship\ it Nice\ post], posts(:hello).comments.order(:position).pluck(:body)
  end

  test "reorder ignores malformed positions" do
    patch administratum.reorder_post_comments_path(posts(:hello)), params: { positions: "nope" }
    assert_response :redirect
    assert_equal [1, 2, 3], [comments(:first), comments(:second), comments(:third)].map { |comment| comment.reload.position }
  end
end
