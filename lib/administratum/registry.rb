# frozen_string_literal: true

module Administratum
  # Finds every resource class. Classes are not stored here: they are looked up
  # through Class#descendants after eager loading the resource directories, so
  # code reloading in development needs no bookkeeping.
  class Registry
    def resources
      ensure_loaded!
      Administratum::Resource.descendants
                             .select { |klass| live?(klass) && !klass.abstract_resource? && enabled?(klass) }
                             .sort_by(&:name)
                             .each { |klass| Ransackable.install(klass.definition.model) }
    end

    def find_by_controller_id(id)
      resources.find { |klass| klass.controller_id == id }
    end

    def pages
      ensure_loaded!
      Administratum::Page.descendants.select { |klass| live?(klass) && !klass.abstract_page? }.sort_by(&:name)
    end

    def find_page_by_controller_id(id)
      pages.find { |klass| klass.controller_id == id }
    end

    def top_level
      resources.reject { |klass| klass.definition.parent }
    end

    def children_of(resource)
      resources.select { |klass| klass.parent_resource == resource }
    end

    # The resource that manages `model` at the top level, falling back to any.
    def for_model(model)
      candidates = resources.select { |klass| klass.definition.model == model }
      candidates.find { |klass| klass.definition.parent.nil? } || candidates.first
    end

    def menu_items
      resources.reject { |klass| klass.definition.menu.hidden || klass.definition.parent || !klass.definition.action_enabled?(:index) }
               .sort_by { |klass| [klass.definition.menu.priority, klass.plural_label] }
    end

    # Resources and pages for the top navigation, by priority then label.
    def navigation
      (menu_items + pages.reject { |page| page.definition.menu.hidden })
        .sort_by { |klass| [klass.definition.menu.priority, klass.menu_label] }
    end

    def ransackable_attributes_for(model)
      resources.select { |klass| model <= klass.definition.model }.flat_map { |klass| klass.definition.ransackable_attributes }.uniq
    end

    def resource_dirs
      dirs = Administratum.config.resource_paths.map { |path| Rails.root.join(path).to_s }
      dirs << Administratum::Engine.root.join("app/admin").to_s
      dirs.select { |dir| Dir.exist?(dir) }
    end

    def reset!
      @loaded = false
    end

    private

    def ensure_loaded!
      return if @loaded

      @loaded = true
      resource_dirs.each { |dir| load_dir(dir) }
    end

    # Another admin (ActiveAdmin, say) may own app/admin and take it away from
    # Zeitwerk. Skip such a directory rather than break route loading.
    def load_dir(dir)
      Rails.autoloaders.main.eager_load_dir(dir)
    rescue Zeitwerk::Error => e
      Rails.logger&.warn("[Administratum] Skipping #{dir}: #{e.message}. Point config.resource_paths at a directory " \
                         "Rails autoloads, e.g. app/admin_next.")
    end

    # After a reload, stale classes can linger in descendants until GC.
    def live?(klass)
      klass.name.present? && klass.name.safe_constantize == klass
    end

    def enabled?(klass)
      Administratum.config.manage_users || klass.name != "Administratum::UserAdmin"
    end
  end
end
