# frozen_string_literal: true

module Administratum
  # Base class for resources declared in app/admin. A resource is a
  # controller: the DSL configures it, the built-in actions provide CRUD, and
  # any public method declared with member_action/collection_action is a
  # custom action. Templates are looked up in app/views/admin/<route_key>
  # first, then in the engine's defaults.
  class Resource < ApplicationController
    extend Administratum::DSL
    include Pagy::Backend

    before_action :load_parent
    before_action :load_resource, if: :member_request?

    helper_method :definition, :resource_class, :paths, :paths_for, :parent_record, :collection_path, :new_resource_path,
                  :resource_path, :edit_resource_path, :action_path, :resource_form_path, :parent_path, :current_index_scope,
                  :index_scope_count

    def index
      collection = current_index_scope ? current_index_scope.apply(scoped_collection) : scoped_collection
      @search = collection.ransack(params[:q], auth_object: :administratum)
      @search.sorts = definition.default_sort if @search.sorts.empty? && definition.default_sort

      respond_to do |format|
        format.html { @pagy, @resources = pagy(@search.result, limit: definition.per_page || Administratum.config.per_page) }
        format.csv { send_data index_csv(@search.result), filename: "#{resource_class.route_key}.csv" } if definition.csv
      end
    end

    def show; end

    def new
      @resource = build_resource
    end

    def edit; end

    def create
      @resource = build_resource(resource_params)

      if @resource.save
        redirect_to after_save_path(@resource), notice: t("administratum.flash.created", resource: resource_class.singular_label)
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @resource.update(resource_params)
        redirect_to after_save_path(@resource), notice: t("administratum.flash.updated", resource: resource_class.singular_label)
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @resource.destroy!
      redirect_to after_destroy_path, notice: t("administratum.flash.destroyed", resource: resource_class.singular_label)
    end

    # Resources defined in the host app live outside the engine's namespace,
    # so Rails hands them the host's url helpers. Point them back at the engine.
    def self.inherited(subclass)
      super
      subclass.include(Administratum::Engine.routes.url_helpers)
      subclass.include(Administratum::Engine.routes.mounted_helpers)
    end

    def self.controller_path
      name.nil? || abstract_resource? ? super : "administratum/resources/#{controller_id}"
    end

    private

    # Templates for this resource live in app/views/<view_prefix>/<route_key>
    # (app/views/admin/posts by default), falling back to the engine's defaults.
    def _prefixes
      @_prefixes ||= ["#{Administratum.config.view_prefix}/#{resource_class.route_key}", "administratum/resources"]
    end

    def resource_class
      self.class
    end

    def definition
      resource_class.definition
    end

    def model
      definition.model
    end

    def parent_record
      @parent
    end

    # Every query for this resource starts here. Override to add includes.
    def scoped_collection
      base = @parent ? @parent.public_send(definition.parent.association) : model.all
      definition.scope_block ? definition.scope_block.call(base) : base
    end

    # The active index tab, from ?scope=, or nil when the resource declares none.
    def current_index_scope
      return @current_index_scope if defined?(@current_index_scope)

      @current_index_scope = definition.index_scope(params[:scope])
    end

    # Records in a tab, with the current filters applied.
    def index_scope_count(index_scope)
      index_scope.apply(scoped_collection).ransack(params[:q], auth_object: :administratum).result.count
    end

    def build_resource(attributes = {})
      @parent ? @parent.public_send(definition.parent.association).build(attributes) : model.new(attributes)
    end

    def resource_params
      params.fetch(model.model_name.param_key, {}).permit(*definition.permitted_params)
    end

    def member_request?
      definition.member_action_names.include?(action_name.to_sym)
    end

    def load_parent
      parent = definition.parent
      return unless parent && params[parent.param]

      @parent = parent.model.find(params[parent.param])
    end

    # Non-shallow nested records are found through the parent; shallow ones
    # get their parent from the record.
    def load_resource
      if @parent
        @resource = scoped_collection.find(params[:id])
      else
        relation = definition.scope_block ? definition.scope_block.call(model.all) : model.all
        @resource = relation.find(params[:id])
        @parent = @resource.public_send(definition.parent.name) if definition.parent
      end
    end

    def after_save_path(record)
      if definition.action_enabled?(:show) then resource_path(record)
      elsif definition.action_enabled?(:edit) then edit_resource_path(record)
      else collection_path
      end
    end

    # Resources without an index page (e.g. nested ones managed from their
    # parent's page) go back to the parent, or the dashboard.
    def after_destroy_path
      return collection_path if definition.action_enabled?(:index)

      parent_path || administratum.root_path
    end

    # Block columns run in a view context, as on the index page, and HTML
    # they return is exported as its text. Columns declared csv: false are left out.
    def index_csv(records)
      columns = definition.index_columns.select(&:csv)
      view = view_context
      CSV.generate do |csv|
        csv << columns.map { |column| view.column_label(column) }
        records.find_each { |record| csv << columns.map { |column| csv_value(view, record, column) } }
      end
    end

    def csv_value(view, record, column)
      value = column.block ? view.instance_exec(record, &column.block) : record.public_send(column.name)

      if value.is_a?(ActiveSupport::SafeBuffer) then Nokogiri::HTML5.fragment(value.to_s).text.strip
      elsif value.is_a?(ActiveRecord::Base) then view.record_title(value)
      else value
      end
    end

    # Paths for this resource. See Administratum::Paths.
    def paths
      @paths ||= Administratum::Paths.new(resource_class, self)
    end

    def paths_for(resource)
      Administratum::Paths.new(resource, self)
    end

    def collection_path(**)
      paths.index(@parent, **)
    end

    def new_resource_path(**)
      paths.new(@parent, **)
    end

    def resource_path(record = @resource, **)
      paths.show(record, **)
    end

    def edit_resource_path(record = @resource, **)
      paths.edit(record, **)
    end

    # Path for a custom action; member actions default to the current record.
    def action_path(name, record = nil, **)
      action = definition.custom_actions.fetch(name.to_sym)
      paths.action(name, record || (action.member? ? @resource : @parent), **)
    end

    def resource_form_path(record = @resource)
      paths.form(record, @parent)
    end

    def parent_path
      return unless @parent

      parent_resource = resource_class.parent_resource
      Administratum::Paths.new(parent_resource, self).show(@parent) if parent_resource.definition.action_enabled?(:show)
    end
  end
end
