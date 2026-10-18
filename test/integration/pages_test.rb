# frozen_string_literal: true

require "test_helper"

class PagesTest < ActionDispatch::IntegrationTest
  setup { sign_in_admin }

  test "renders the default page with the host's content partial and header buttons" do
    get administratum.reports_page_path
    assert_response :success
    assert_select "h1", text: "Reports"
    assert_select "#post-count", text: "2"
    assert_select "form[action=?] button", administratum.refresh_reports_page_path, text: "Refresh"
    assert_select "form[action=?][data-adm-confirm=?]", administratum.refresh_reports_page_path, "Refresh the report?"
    assert_select "a[href=?]", administratum.weekly_reports_page_path, text: "Weekly"
  end

  test "is in the navigation by priority, and marked active" do
    get administratum.reports_page_path
    labels = css_select(".adm-nav-link").map { |link| link.text.strip }
    assert_equal %w[Dashboard Reports Posts], labels.first(3)
    assert_select ".adm-nav-link-active[aria-current=page]", text: "Reports"
    assert_select ".adm-nav-link", text: "Maintenance tools", count: 0
  end

  test "a POST page action runs the page's method" do
    post administratum.refresh_reports_page_path
    assert_redirected_to administratum.reports_page_path
    assert_equal "Report refreshed", flash[:notice]
  end

  test "a GET page action without a method renders its template, with a breadcrumb back" do
    get administratum.weekly_reports_page_path
    assert_response :success
    assert_select "#weekly"
    assert_select ".adm-breadcrumb a[href=?]", administratum.reports_page_path, text: "Reports"
  end

  test "label, route and an overridden index template" do
    get "/administratum/tools"
    assert_response :success
    assert_select "h1", text: "Maintenance tools"
    assert_select "#tools"
  end

  test "requires a signed-in admin" do
    delete administratum.sign_out_path
    get administratum.reports_page_path
    assert_redirected_to administratum.sign_in_path
  end

  test "pages are not dashboard tiles" do
    get administratum.root_path
    assert_select ".adm-tile-label", text: "Reports", count: 0
  end
end
