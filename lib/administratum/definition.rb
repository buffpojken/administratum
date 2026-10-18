# frozen_string_literal: true

module Administratum
  # Everything a resource class declares through the DSL. Each resource class
  # owns one; subclasses start from a deep copy of their parent's.
  #
  # Declarations are stored as given and resolved lazily (types inferred from
  # the schema on first use), because resource classes are loaded to draw
  # routes, which also happens when the database doesn't exist yet.
  class Definition
    BUILT_IN_ACTIONS = %i[index show new create edit update destroy].freeze

    Field = Struct.new(:name, :declared_type, :options, :definition, keyword_init: true) do
      def model = definition.model
      def type = (declared_type || Administratum.field_types.infer(model, name)).to_sym
      def label = options[:label]
      def hint = options[:hint]
    end

    Column = Struct.new(:name, :declared_type, :label, :declared_sortable, :block, :definition, keyword_init: true) do
      def model = definition.model

      def type
        return declared_type if declared_type
        return :association if model.reflect_on_association(name)&.macro == :belongs_to

        case model.columns_hash[name.to_s]&.type
        when :boolean then :boolean
        when :datetime then :datetime
        when :date then :date
        else :text
        end
      end

      def sortable
        declared_sortable.nil? ? block.nil? && model.columns_hash.key?(name.to_s) : declared_sortable
      end
    end

    Filter = Struct.new(:name, :declared_type, :label, :declared_collection, :declared_predicate, :definition,
                        keyword_init: true) do
      def model = definition.model

      def type
        return declared_type if declared_type
        return :select if belongs_to_reflection

        case model.columns_hash[name.to_s]&.type
        when :boolean then :boolean
        when :integer, :float, :decimal then :number
        when :date, :datetime then :date_range
        else :string
        end
      end

      def predicate
        declared_predicate || (type == :string ? :cont : :eq)
      end

      def collection
        return declared_collection if declared_collection
        return unless type == :select

        reflection = belongs_to_reflection
        -> { reflection.klass.all } if reflection
      end

      def keys
        type == :date_range ? ["#{name}_gteq", "#{name}_lteq"] : ["#{name}_#{predicate}"]
      end

      private

      def belongs_to_reflection
        return unless name.to_s.end_with?("_id")

        reflection = model.reflect_on_association(name.to_s.delete_suffix("_id").to_sym)
        reflection if reflection&.macro == :belongs_to
      end
    end

    CustomAction = Struct.new(:name, :http_method, :scope, keyword_init: true) do
      def member? = scope == :member
    end

    Button = Struct.new(:name, :label, :pages, :action, :to, :http_method, :confirm, :condition, :style, :panel, :upload,
                        keyword_init: true)

    Parent = Struct.new(:name, :class_name, :shallow, :association, keyword_init: true) do
      def model = class_name.constantize
      def param = :"#{name}_id"
    end

    Menu = Struct.new(:label, :priority, :hidden, keyword_init: true)

    # A tab above the index table. Without a block it calls the model scope of the same name.
    IndexScope = Struct.new(:name, :label, :block, :default, :count, keyword_init: true) do
      def apply(relation) = block ? block.call(relation) : relation.public_send(name)
      def display_label = label || I18n.t("administratum.scopes.#{name}", default: name.to_s.humanize)
    end

    attr_accessor :model, :title_attribute, :permitted, :parent, :form_template, :scope_block, :route_key, :label,
                  :plural_label, :per_page, :default_sort, :csv
    attr_reader :fields, :columns, :custom_actions, :buttons, :show_attributes, :enabled_actions, :menu, :index_scopes

    def initialize
      @fields = []
      @columns = []
      @filters = nil
      @custom_actions = {}
      @buttons = []
      @show_attributes = []
      @index_scopes = []
      @enabled_actions = BUILT_IN_ACTIONS.dup
      @menu = Menu.new(priority: 100, hidden: false)
      @csv = false
    end

    def initialize_copy(source)
      super
      @fields = rebind(source.fields)
      @columns = rebind(source.columns)
      @filters = source.declared_filters && rebind(source.declared_filters)
      @custom_actions = source.custom_actions.dup
      @buttons = source.buttons.map(&:dup)
      @show_attributes = rebind(source.show_attributes)
      @index_scopes = source.index_scopes.dup
      @enabled_actions = source.enabled_actions.dup
      @menu = source.menu.dup
    end

    def declared_filters
      @filters
    end

    def title
      title_attribute || %i[title name].find { |attr| model.column_names.include?(attr.to_s) || model.method_defined?(attr) }
    end

    # Filters default to a "contains" search on the title attribute.
    def filters
      return @filters if @filters

      title && model.column_names.include?(title.to_s) ? [build_filter(title)] : []
    end

    def add_filter(name, **)
      @filters ||= []
      @filters.reject! { |filter| filter.name == name.to_sym }
      @filters << build_filter(name, **)
    end

    def clear_filters!
      @filters = []
    end

    def build_filter(name, as: nil, label: nil, collection: nil, predicate: nil)
      Filter.new(name: name.to_sym, declared_type: as&.to_sym, label:, declared_collection: collection,
                 declared_predicate: predicate&.to_sym, definition: self)
    end

    def index_columns
      return columns if columns.any?

      [:id, title, :updated_at].compact.uniq.select { |name| model.column_names.include?(name.to_s) }.map { |name| build_column(name) }
    end

    def add_column(name, as: nil, label: nil, sortable: nil, &)
      columns.reject! { |column| column.name == name.to_sym }
      columns << build_column(name, as:, label:, sortable:, &)
    end

    def build_column(name, as: nil, label: nil, sortable: nil, &block)
      Column.new(name: name.to_sym, declared_type: as&.to_sym, label:, declared_sortable: sortable, block:, definition: self)
    end

    def add_field(name, as: nil, **options)
      fields.reject! { |field| field.name == name.to_sym }
      fields << Field.new(name: name.to_sym, declared_type: as&.to_sym, options:, definition: self)
    end

    def field(name)
      fields.find { |field| field.name == name.to_sym }
    end

    # The argument list passed to `permit`, with hash entries last as strong params requires.
    def permitted_params
      return permitted if permitted

      scalars = []
      nested = {}
      fields.each do |field|
        case Administratum.field_types.fetch(field.type).param
        when :array then nested[field.name] = []
        when :hash then nested[field.name] = {}
        else scalars << field.name
        end
      end
      nested.empty? ? scalars : scalars + [nested]
    end

    # Attribute names Ransack may filter and sort on for this resource.
    def ransackable_attributes
      names = filters.map { |filter| filter.name.to_s }
      names += index_columns.select(&:sortable).map { |column| column.name.to_s }
      names << title.to_s if title
      names += Array(default_sort).map { |sort| sort.to_s.split.first }
      names.uniq & model.column_names
    end

    def add_action(name, http_method:, scope:)
      custom_actions[name.to_sym] = CustomAction.new(name: name.to_sym, http_method: http_method.to_sym, scope:)
    end

    def member_actions
      custom_actions.values.select(&:member?)
    end

    def collection_actions
      custom_actions.values.reject(&:member?)
    end

    def member_action_names
      %i[show edit update destroy] + member_actions.map(&:name)
    end

    def enable_actions(only: nil, except: nil)
      list = only ? Array(only).map(&:to_sym) : BUILT_IN_ACTIONS.dup
      list -= Array(except).map(&:to_sym)
      # A form is useless without the action that receives it.
      list |= [:create] if list.include?(:new)
      list |= [:update] if list.include?(:edit)
      @enabled_actions = list & BUILT_IN_ACTIONS
    end

    def action_enabled?(name)
      enabled_actions.include?(name.to_sym)
    end

    def add_button(name, on:, label: nil, action: nil, to: nil, method: nil, confirm: nil, condition: nil, style: :secondary,
                   panel: nil, upload: false)
      buttons << Button.new(name: name.to_sym, label:, pages: Array(on).map(&:to_sym), action: (action || name).to_sym, to:,
                            http_method: method&.to_sym, confirm:, condition:, style: style.to_sym, panel:, upload:)
    end

    def buttons_for(page)
      buttons.select { |button| button.pages.include?(page.to_sym) }
    end

    def add_index_scope(name, label: nil, default: false, count: true, &block)
      index_scopes.reject! { |index_scope| index_scope.name == name.to_sym }
      index_scopes << IndexScope.new(name: name.to_sym, label:, block:, default:, count:)
    end

    # The tab named by `name`, else the default tab (the first one unless one says `default: true`).
    def index_scope(name)
      index_scopes.find { |index_scope| index_scope.name.to_s == name.to_s } ||
        index_scopes.find(&:default) || index_scopes.first
    end

    def add_show_attribute(name, as: nil, label: nil, &)
      show_attributes << build_column(name, as:, label:, sortable: false, &)
    end

    def resolved_show_attributes
      return show_attributes if show_attributes.any?

      names = [:id] + fields.reject { |field| %i[password hidden].include?(field.type) }.map(&:name)
      names = index_columns.map(&:name) if fields.empty?
      names += %i[created_at updated_at]
      names.uniq.select { |name| model.column_names.include?(name.to_s) || model.method_defined?(name) }
           .map { |name| build_column(name, sortable: false) }
    end

    private

    def rebind(items)
      items.map { |item| item.dup.tap { |copy| copy.definition = self } }
    end
  end
end
