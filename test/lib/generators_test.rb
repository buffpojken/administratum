# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/administratum/resource/resource_generator"
require "administratum/tailwind"

class ResourceGeneratorTest < Rails::Generators::TestCase
  tests Administratum::Generators::ResourceGenerator
  destination File.expand_path("../../tmp/generators", __dir__)
  setup :prepare_destination

  test "writes a resource with fields from the schema" do
    run_generator ["Post"]
    assert_file "app/admin/post_admin.rb" do |content|
      assert_match(/class PostAdmin < Administratum::Resource/, content)
      assert_match(/field :title/, content)
      assert_no_match(/field :created_at/, content)
    end
  end
end

class TailwindSyncTest < ActiveSupport::TestCase
  test "points at the installed gem's sources" do
    css = Administratum::Tailwind.contents
    assert_includes css, "#{Administratum::Tailwind.root}/app/assets/tailwind/administratum/theme.css"
    assert_includes css, "@source \"#{Administratum::Tailwind.root}/app/views\""
    assert File.exist?("#{Administratum::Tailwind.root}/app/assets/tailwind/administratum/theme.css")
  end
end
