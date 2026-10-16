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

      Administratum.registry.ransackable_attributes_for(self) | own_allowlist { super }
    end

    def ransackable_associations(auth_object = nil)
      return super unless auth_object == :administratum

      own_allowlist { super }
    end

    private

    # Ransack's defaults raise when a model has no allowlist.
    def own_allowlist
      Array(yield).map(&:to_s)
    rescue RuntimeError
      []
    end
  end
end
