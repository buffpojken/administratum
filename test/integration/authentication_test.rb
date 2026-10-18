# frozen_string_literal: true

require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "redirects to sign in when signed out" do
    get administratum.posts_path
    assert_redirected_to administratum.sign_in_path
  end

  test "signs in and returns to the requested page" do
    get administratum.posts_path
    sign_in_admin
    assert_redirected_to administratum.posts_path
  end

  test "remember me sets a remember cookie" do
    post administratum.sign_in_path, params: { email: "admin@example.com", password: "password123", remember_me: "1" }
    assert_redirected_to administratum.root_path
    assert cookies["remember_administratum_user_token"].present?
  end

  test "rejects a wrong password" do
    post administratum.sign_in_path, params: { email: "admin@example.com", password: "nope" }
    assert_response :unprocessable_content
    assert_select ".adm-flash-alert", /Invalid email or password/
  end

  test "signs out of the admin scope only" do
    sign_in_admin
    get administratum.root_path
    assert_response :success

    get "/host_session"
    delete administratum.sign_out_path
    assert_redirected_to administratum.sign_in_path
    assert_nil session["warden.user.administratum_user.key"]
    assert_equal "kept", session[:host_value]
  end

  test "password reset round trip" do
    assert_enqueued_emails 1 do
      post administratum.password_reset_path, params: { email: "admin@example.com" }
    end
    assert_redirected_to administratum.sign_in_path

    user = administratum_users(:admin)
    token = user.send(:set_reset_password_token)
    patch administratum.password_reset_path, params: { token:, password: "newpassword1", password_confirmation: "newpassword1" }
    assert_redirected_to administratum.sign_in_path
    assert user.reload.valid_password?("newpassword1")
  end

  test "password reset does not reveal unknown emails" do
    assert_no_enqueued_emails do
      post administratum.password_reset_path, params: { email: "nobody@example.com" }
    end
    assert_redirected_to administratum.sign_in_path
  end
end
