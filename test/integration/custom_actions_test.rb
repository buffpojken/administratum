# frozen_string_literal: true

require "test_helper"

class CustomActionsTest < ActionDispatch::IntegrationTest
  setup { sign_in_admin }

  test "custom member page renders its template with an island" do
    get administratum.write_post_path(posts(:hello))
    assert_response :success
    assert_select "[data-administratum-island=post-writer] script[type='application/json']" do |scripts|
      props = JSON.parse(scripts.first.text)
      assert_equal "First post", props["body"]
      assert_equal administratum.save_body_post_path(posts(:hello)), props["saveUrl"]
      assert props.key?("csrfToken")
    end
  end

  test "json member action" do
    patch administratum.save_body_post_path(posts(:hello)), params: { body: "Rewritten" }, as: :json
    assert_response :success
    assert_equal "Rewritten", response.parsed_body["body"]
  end

  test "conditional button with confirmation" do
    get administratum.post_path(posts(:hello))
    assert_select "form[action=?][data-adm-confirm='Publish this post?']", administratum.publish_post_path(posts(:hello))

    get administratum.post_path(posts(:draft))
    assert_select "form[action=?]", administratum.publish_post_path(posts(:draft)), count: 0
  end

  test "link button to a nested resource" do
    get administratum.post_path(posts(:hello))
    assert_select "a[href=?]", administratum.post_comments_path(posts(:hello)), text: "Comments"
  end

  test "post member action" do
    post administratum.publish_post_path(posts(:hello))
    assert_redirected_to administratum.post_path(posts(:hello))
    assert posts(:hello).reload.published
  end

  test "collection actions export and import" do
    get administratum.export_posts_path
    assert_includes response.body, "Hello world"

    file = Rack::Test::UploadedFile.new(StringIO.new([{ title: "Imported" }].to_json), "application/json", original_filename: "posts.json")
    assert_difference("Post.count") { post administratum.import_posts_path, params: { file: } }
    assert_redirected_to administratum.posts_path
  end

  test "upload button renders an offcanvas form" do
    get administratum.posts_path
    assert_select "[data-adm-offcanvas=adm-panel-import] form[action=?][enctype='multipart/form-data']", administratum.import_posts_path
  end
end
