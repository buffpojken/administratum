# frozen_string_literal: true

require "csv"
require "devise"
require "ransack"
require "pagy"

require "administratum/version"
require "administratum/configuration"
require "administratum/field_types"
require "administratum/definition"
require "administratum/dsl"
require "administratum/page_dsl"
require "administratum/paths"
require "administratum/reorder"
require "administratum/registry"
require "administratum/ransackable"
require "administratum/routing"
require "administratum/engine"

module Administratum
  class Error < StandardError; end

  def self.config
    @config ||= Configuration.new
  end

  def self.configure
    yield config
  end

  def self.registry
    @registry ||= Registry.new
  end

  def self.field_types
    config.field_types
  end

  # Used by tests to start from a clean configuration.
  def self.reset_config!
    @config = Configuration.new
  end
end
