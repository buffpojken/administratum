# frozen_string_literal: true

module Administratum
  # Prepended to each managed model's singleton class. When Ransack is called
  # with auth_object: :administratum, the attributes a resource declares as
  # filters or sortable columns are allowed, so models need no allowlist of
  # their own. Other callers see the model's own allowlist unchanged.
  module Ransackable
    def self.install(model)
      return if model.singleton_class.include?(self)

      model.singleton_class.prepend(self)
    end

    def ransackable_attributes(auth_object = nil)
      return super unless auth_object == :administratum

      Administratum.registry.ransackable_attributes_for(self) | own_allowlist(:ransackable_attributes, auth_object)
    end

    def ransackable_associations(auth_object = nil)
      return super unless auth_object == :administratum

      own_allowlist(:ransackable_associations, auth_object)
    end

    private

    # The model's own allowlist, if it defines one. Ransack's default either
    # raises (Ransack 4.1+) or, in some 4.x versions, allows every column with a
    # deprecation warning; neither should widen what the admin can search.
    def own_allowlist(name, auth_object)
      definition = method(name).super_method
      return [] if definition.nil? || definition.owner.name.to_s.start_with?("Ransack::")

      Array(definition.call(auth_object)).map(&:to_s)
    rescue RuntimeError
      []
    end
  end
end
