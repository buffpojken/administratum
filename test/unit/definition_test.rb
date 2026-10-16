# frozen_string_literal: true

require "test_helper"

class DefinitionTest < ActiveSupport::TestCase
  test "infers field types from the schema" do
    fields = PostAdmin.definition.fields.index_by(&:name)
    assert_equal :string, fields[:title].type
    assert_equal :boolean, fields[:published].type
    assert_equal :belongs_to, fields[:category_id].type
    assert_equal :has_many_ids, fields[:tag_ids].type
    assert_equal :color, fields[:color].type
  end

  test "permits scalars first and arrays last" do
    assert_equal [:title, :body, :published, :category_id, :color, :metadata, { tag_ids: [] }],
                 PostAdmin.definition.permitted_params
  end

  test "filters default to the title" do
    assert_equal [:name], CategoryAdmin.definition.filters.map(&:name)
    assert_equal ["name_cont"], CategoryAdmin.definition.filters.first.keys
  end

  test "infers filter predicates" do
    filters = PostAdmin.definition.filters.index_by(&:name)
    assert_equal ["title_cont"], filters[:title].keys
    assert_equal ["published_eq"], filters[:published].keys
    assert_equal :select, filters[:category_id].type
  end

  test "ransack allowlist covers declared filters and sortable columns" do
    assert_includes Post.ransackable_attributes(:administratum), "title"
    assert_includes Post.ransackable_attributes(:administratum), "published"
    assert_includes Post.ransackable_attributes(:administratum), "created_at"
  end

  test "subclasses copy their parent's definition" do
    child = Class.new(PostAdmin)
    child.definition.add_field(:extra)
    assert_nil PostAdmin.definition.field(:extra)
    assert_equal child.definition, child.definition.fields.first.definition
  end

  test "enabling new also enables create" do
    definition = Administratum::Definition.new
    definition.enable_actions(only: %i[index new])
    assert_equal %i[index new create], definition.enabled_actions
  end
end
