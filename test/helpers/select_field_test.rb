# frozen_string_literal: true

require "test_helper"

class SelectFieldTest < ActionView::TestCase
  include Administratum::ApplicationHelper
  helper Administratum::ApplicationHelper

  test "group_by renders optgroups" do
    Category.create!(name: "Opinion")
    select = render_select(group_by: ->(category) { category.name.start_with?("N") ? "N" : "Other" })
    assert_equal %w[N Other], select.css("optgroup").map { |group| group["label"] }.sort
    assert_equal "News", select.at("optgroup[label=N] option[selected]").text
  end

  test "remote search renders only the current value" do
    select = render_select(searchable: { url: ->(post) { "/search?post=#{post.id}" }, min: 3 })
    assert_equal "/search?post=#{posts(:hello).id}", select["data-adm-combobox-url"]
    assert_equal "3", select["data-adm-combobox-min"]
    assert_equal "Type at least %{count} characters", select["data-adm-combobox-short"]
    assert_equal ["", "News"], select.css("option").map(&:text)
  end

  test "adm_combobox_data marks a hand-written select" do
    data = adm_combobox_data(url: "/templates/search")
    assert data[:adm_combobox]
    assert_equal "/templates/search", data[:adm_combobox_url]
    assert_not data.key?(:adm_combobox_min)
  end

  private

  def render_select(**options)
    field = Administratum::Definition::Field.new(name: :category_id, declared_type: :belongs_to, options:, definition: PostAdmin.definition)
    html = form_with(model: posts(:hello), url: "/posts") { |form| render_field(form, field) }
    Nokogiri::HTML.fragment(html).at("select")
  end
end
