# frozen_string_literal: true

require "test_helper"

class RegistryTest < ActiveSupport::TestCase
  test "skips a resource directory Zeitwerk doesn't manage instead of raising" do
    dir = Rails.root.join("tmp/unmanaged_admin")
    FileUtils.mkdir_p(dir)
    Administratum.config.resource_paths = ["app/admin", "tmp/unmanaged_admin"]
    Administratum.registry.reset!

    assert_includes Administratum.registry.resources, PostAdmin
  ensure
    Administratum.config.resource_paths = ["app/admin"]
    Administratum.registry.reset!
  end
end
