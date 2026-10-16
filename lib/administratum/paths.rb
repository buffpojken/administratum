# frozen_string_literal: true

module Administratum
  # Builds paths for a resource class from the route names Routing draws.
  # `context` is anything that responds to the engine's *_path helpers.
  class Paths
    def initialize(resource, context)
      @resource = resource
      @context = context
    end

    def index(parent = nil, **query)
      call(collection_name, nested? ? [parent] : [], query)
    end

    def new(parent = nil, **query)
      call("new_#{nested? ? "#{parent_key}_" : ''}#{singular}", nested? ? [parent] : [], query)
    end

    def show(record, **query)
      call(member_name, member_args(record), query)
    end

    def edit(record, **query)
      call("edit_#{member_name}", member_args(record), query)
    end

    # Path for a custom action. Member actions take the record, collection
    # actions take the parent (when nested) or nothing.
    def action(name, record_or_parent = nil, **query)
      action = @resource.definition.custom_actions.fetch(name.to_sym)
      if action.member?
        call("#{name}_#{member_name}", member_args(record_or_parent), query)
      else
        call("#{name}_#{collection_name}", nested? ? [record_or_parent] : [], query)
      end
    end

    # Where a form for `record` submits to.
    def form(record, parent = nil)
      record.persisted? ? show(record) : index(parent || parent_of(record))
    end

    def parent_of(record)
      return unless nested?

      record.public_send(@resource.definition.parent.name)
    end

    private

    def call(name, args, query)
      @context.public_send(:"#{name}_path", *args, **query)
    end

    def nested?
      @resource.definition.parent.present?
    end

    def shallow?
      nested? && @resource.definition.parent.shallow
    end

    def singular
      @resource.singular_route_key
    end

    def parent_key
      @resource.parent_resource.singular_route_key
    end

    def collection_name
      base = @resource.route_key == singular ? "#{singular}_index" : @resource.route_key
      nested? ? "#{parent_key}_#{base}" : base
    end

    def member_name
      nested? && !shallow? ? "#{parent_key}_#{singular}" : singular
    end

    def member_args(record)
      nested? && !shallow? ? [parent_of(record), record] : [record]
    end
  end
end
