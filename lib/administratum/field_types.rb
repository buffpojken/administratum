# frozen_string_literal: true

module Administratum
  # Registry of form field types. Each type is a partial plus the shape its
  # value takes in strong params (:scalar, :array or :hash).
  class FieldTypes
    Type = Struct.new(:name, :partial, :param, keyword_init: true)

    PARAM_SHAPES = %i[scalar array hash].freeze

    BUILT_IN = {
      string: :scalar,
      textarea: :scalar,
      number: :scalar,
      boolean: :scalar,
      select: :scalar,
      multi_select: :array,
      belongs_to: :scalar,
      has_many_ids: :array,
      date: :scalar,
      datetime: :scalar,
      email: :scalar,
      password: :scalar,
      hidden: :scalar,
      json: :scalar,
      island: :scalar
    }.freeze

    COLUMN_TYPES = {
      text: :textarea,
      integer: :number,
      float: :number,
      decimal: :number,
      boolean: :boolean,
      date: :date,
      datetime: :datetime,
      json: :json,
      jsonb: :json
    }.freeze

    def initialize
      @types = {}
      BUILT_IN.each { |name, param| register(name, partial: "administratum/fields/#{name}", param:) }
    end

    # Registers a field type. The partial receives form:, field:, resource: and value:.
    def register(name, partial:, param: :scalar)
      raise ArgumentError, "param must be one of #{PARAM_SHAPES.join(', ')}" unless PARAM_SHAPES.include?(param)

      @types[name.to_sym] = Type.new(name: name.to_sym, partial:, param:)
    end

    def fetch(name)
      @types.fetch(name.to_sym) { raise Administratum::Error, "Unknown field type :#{name}. Register it with config.field_types.register." }
    end

    def key?(name)
      @types.key?(name.to_sym)
    end

    # Picks a field type from the model's column when `as:` is not given.
    def infer(model, attribute)
      name = attribute.to_s
      return :password if name.include?("password")
      return :email if name == "email"

      reflection = model.reflect_on_association(name.delete_suffix("_id").to_sym)
      return :belongs_to if name.end_with?("_id") && reflection&.macro == :belongs_to
      return :has_many_ids if name.end_with?("_ids")

      column = model.columns_hash[name]
      return :string unless column

      COLUMN_TYPES.fetch(column.type, :string)
    end
  end
end
