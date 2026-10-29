# frozen_string_literal: true

module Administratum
  # Class-level DSL for resource classes. See README for the full reference.
  module DSL
    # Declarations shared by resources and pages.
    module Common
      # A button on one or more pages (:index, :show, :new, :edit, :row, :page or a
      # custom action's name). It triggers the custom action of the same name
      # unless `action:` or `to:` (a lambda returning a path) is given.
      def button(name, on:, label: nil, action: nil, to: nil, method: nil, confirm: nil, if: nil, style: :secondary,
                 panel: nil, upload: false)
        definition.add_button(name, on:, label:, action:, to:, method:, confirm:, condition: binding.local_variable_get(:if),
                                    style:, panel:, upload:)
      end

      # `menu false` hides it from navigation.
      def menu(options = {})
        if options == false
          definition.menu.hidden = true
        else
          definition.menu.label = options[:label] if options[:label]
          definition.menu.priority = options[:priority] if options[:priority]
        end
      end

      def route(key)
        definition.route_key = key.to_s
      end

      def controller_id
        name.underscore.tr("/", "_")
      end
    end

    include Common

    # Builds `aside do ... end` button lists. Buttons take the same options as
    # `button`, except `on:`, which comes from the aside.
    class AsideBuilder
      def initialize(definition, aside)
        @definition = definition
        @aside = aside
      end

      def button(name, label: nil, action: nil, to: nil, method: nil, confirm: nil, if: nil, style: :secondary, panel: nil,
                 upload: false)
        @aside.buttons << @definition.build_button(name, on: @aside.pages, label:, action:, to:, method:, confirm:,
                                                         condition: binding.local_variable_get(:if), style:, panel:, upload:)
      end
    end

    # Builds `form do ... end` field lists.
    class FormBuilder
      def initialize(definition)
        @definition = definition
      end

      def field(name, as: nil, **options)
        @definition.add_field(name, as:, **options)
      end
    end

    # Builds `index do ... end` column lists.
    class IndexBuilder
      def initialize(definition)
        @definition = definition
      end

      def column(name, as: nil, label: nil, sortable: nil, csv: true, &block)
        @definition.add_column(name, as:, label:, sortable:, csv:, &block)
      end
    end

    # Builds `show do ... end` attribute lists.
    class ShowBuilder
      def initialize(definition)
        @definition = definition
      end

      # `if:` takes a lambda, run in the view, that receives the record when it takes an argument.
      def attribute(name, as: nil, label: nil, if: nil, &)
        @definition.add_show_attribute(name, as:, label:, condition: binding.local_variable_get(:if), &)
      end
    end

    def definition
      @definition ||= superclass.respond_to?(:definition) ? superclass.definition.dup : Definition.new
      @definition.model ||= inferred_model unless abstract_resource?
      @definition
    end

    # Marks a class as a base for other resources: it gets no routes or menu entry.
    def abstract_resource!
      @abstract_resource = true
    end

    def abstract_resource?
      @abstract_resource == true || name == "Administratum::Resource"
    end

    def model(klass = nil)
      definition.model = klass if klass
      definition.model
    end

    def title(attribute)
      definition.title_attribute = attribute.to_sym
    end

    def label(singular, plural: nil)
      definition.label = singular
      definition.plural_label = plural
    end

    # Replaces the filter list. `filters` with no arguments disables filtering.
    def filters(*names)
      definition.clear_filters!
      names.each { |name| definition.add_filter(name) }
    end

    def filter(name, as: nil, label: nil, collection: nil, predicate: nil)
      definition.add_filter(name, as:, label:, collection:, predicate:)
    end

    def index(per_page: nil, sort: nil, csv: nil, &block)
      definition.per_page = per_page if per_page
      definition.default_sort = sort if sort
      definition.csv = csv unless csv.nil?
      IndexBuilder.new(definition).instance_eval(&block) if block
    end

    def form(template: nil, &block)
      definition.form_template = template if template
      FormBuilder.new(definition).instance_eval(&block) if block
    end

    def show(&)
      ShowBuilder.new(definition).instance_eval(&)
    end

    # A menu of buttons beside the content of :index, :show, :new or :edit,
    # for actions too minor for the page header. `title:` defaults to "Actions".
    def aside(on:, title: nil, &)
      AsideBuilder.new(definition, definition.add_aside(on:, title:)).instance_eval(&)
    end

    # Strong-params style list of writable attributes. Defaults to the form fields.
    def permit(*attributes)
      definition.permitted = attributes
    end

    # With a block only, narrows every query this resource makes (the block receives the relation).
    # With a name, adds a tab above the index: `scope :published` calls Post.published, or pass a
    # block. Options: `default: true`, `label:`, `count: false` to skip the count query.
    def scope(name = nil, label: nil, default: false, count: true, &block)
      return definition.add_index_scope(name, label:, default:, count:, &block) if name

      definition.scope_block = block
    end

    # Nests this resource under another: `parent :fantasy, shallow: true`.
    def parent(name, shallow: false, association: nil, class_name: nil)
      definition.parent = Definition::Parent.new(
        name: name.to_sym,
        class_name: class_name || name.to_s.classify,
        shallow:,
        association: (association || definition.model.model_name.plural).to_sym
      )
    end

    def actions(only: nil, except: nil)
      definition.enable_actions(only:, except:)
    end

    # Records are put in order by an integer column. Adds a PATCH `reorder`
    # collection action taking positions[id]=n, sorts the index by the column,
    # and shows reorder controls there while every record is on the page.
    def reorderable(column = :position)
      definition.reorder_column = column.to_sym
      definition.default_sort ||= "#{column} asc"
      collection_action :reorder, method: :patch
    end

    def member_action(name, method: :get)
      definition.add_action(name, http_method: method, scope: :member)
    end

    def collection_action(name, method: :get)
      definition.add_action(name, http_method: method, scope: :collection)
    end

    def route_key
      definition.route_key || definition.model.model_name.route_key
    end

    def singular_route_key
      definition.route_key ? definition.route_key.singularize : definition.model.model_name.singular_route_key
    end

    def parent_resource
      return unless definition.parent

      Administratum.registry.for_model(definition.parent.model)
    end

    def singular_label
      definition.label || definition.model.model_name.human
    end

    def plural_label
      definition.plural_label || definition.model.model_name.human(count: 2, default: singular_label.pluralize)
    end

    def menu_label
      definition.menu.label || plural_label
    end

    private

    def inferred_model
      name&.delete_suffix("Admin")&.safe_constantize
    end
  end
end
