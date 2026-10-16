# frozen_string_literal: true

require "test_helper"

class NestedTest < ActionDispatch::IntegrationTest
  setup { sign_in_admin }

  test "shallow children list under the parent" do
    get administratum.post_comments_path(posts(:hello))
    assert_response :success
    assert_select "td", text: "Nice post"
    assert_select ".adm-breadcrumb a", text: "Hello world"
  end

  test "shallow children are created through the parent" do
    assert_difference("posts(:hello).comments.count") do
      post administratum.post_comments_path(posts(:hello)), params: { comment: { body: "Hi", author: "Bob" } }
    end
    assert_redirected_to administratum.comment_path(Comment.order(:id).last)
  end

  test "shallow member routes resolve the parent from the record" do
    get administratum.edit_comment_path(comments(:first))
    assert_response :success
    assert_select "form[action=?]", administratum.comment_path(comments(:first))
    assert_select ".adm-breadcrumb a", text: "Hello world"
  end

  test "non-shallow children are scoped to the parent" do
    get administratum.edit_post_attachment_path(posts(:hello), attachments(:photo))
    assert_response :success
    assert_select "form[action=?]", administratum.post_attachment_path(posts(:hello), attachments(:photo))

    get administratum.edit_post_attachment_path(posts(:draft), attachments(:photo))
    assert_response :not_found
  end

  test "non-shallow create redirects to edit when show is disabled" do
    post administratum.post_attachments_path(posts(:draft)), params: { attachment: { name: "doc.pdf" } }
    attachment = Attachment.order(:id).last
    assert_equal posts(:draft), attachment.post
    assert_redirected_to administratum.edit_post_attachment_path(posts(:draft), attachment)
  end

  test "destroying without an index page returns to the parent" do
    AttachmentAdmin.definition.enable_actions(except: %i[show index])
    delete administratum.post_attachment_path(posts(:hello), attachments(:photo))
    assert_redirected_to administratum.post_path(posts(:hello))
  ensure
    AttachmentAdmin.definition.enable_actions(except: :show)
  end
end
