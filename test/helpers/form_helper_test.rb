# frozen_string_literal: true

require "test_helper"

class FormHelperTest < ActionView::TestCase
  include Administratum::FormHelper

  test "adm_date_field renders an ISO text input" do
    html = form_with(model: Post.new, url: "/posts") { |form| adm_date_field(form, :published_on, value: Date.new(2026, 3, 4)) }
    assert_dom_equal(
      '<input value="2026-03-04" placeholder="YYYY-MM-DD" pattern="\d{4}-\d{2}-\d{2}" inputmode="numeric" class="adm-input" type="text" name="post[published_on]" id="post_published_on">',
      Nokogiri::HTML.fragment(html).at("input[type=text]").to_html
    )
  end

  test "adm_datetime_field formats the attribute in the app time zone" do
    post = Post.new(created_at: Time.utc(2026, 3, 4, 23, 30))
    html = Time.use_zone("Stockholm") do
      post.created_at = post.created_at.in_time_zone
      form_with(model: post, url: "/posts") { |form| adm_datetime_field(form, :created_at, class: "wide") }
    end
    input = Nokogiri::HTML.fragment(html).at("input[type=text]")
    assert_equal "2026-03-05 00:30", input["value"]
    assert_equal "YYYY-MM-DD HH:MM", input["placeholder"]
    assert_equal "wide", input["class"]
  end

  test "keeps a typed string that is not a date" do
    html = form_with(model: Post.new, url: "/posts") { |form| adm_date_field(form, :title, value: "2026-13-01") }
    assert_equal "2026-13-01", Nokogiri::HTML.fragment(html).at("input[type=text]")["value"]
  end
end
