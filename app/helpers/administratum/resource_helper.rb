# frozen_string_literal: true

module Administratum
  module ResourceHelper
    BUTTON_STYLES = {
      primary: "adm-btn adm-btn-primary",
      secondary: "adm-btn adm-btn-secondary",
      danger: "adm-btn adm-btn-danger",
      ghost: "adm-btn adm-btn-ghost"
    }.freeze

    # The display name of any record: its resource's title attribute, else to_s.
    def record_title(record)
      return "" if record.nil?

      resource = Administratum.registry.for_model(record.class)
      attribute = resource&.definition&.title
      value = attribute ? record.public_send(attribute) : nil
      value.presence&.to_s || "#{record.model_name.human} ##{record.id}"
    end

    def column_label(column)
      column.label || definition.model.human_attribute_name(column.name)
    end

    def column_value(record, column)
      return instance_exec(record, &column.block) if column.block

      format_value(record.public_send(column.name), column.type)
    end

    def format_value(value, type = nil)
      return tag.span("–", class: "adm-muted") if value.nil? || value == ""

      case type
      when :boolean then boolean_badge(value)
      when :datetime then l(value, format: :short)
      when :date then l(value)
      when :association then link_to_record(value)
      else
        if value.is_a?(ActiveRecord::Base) then link_to_record(value)
        elsif value == true || value == false then boolean_badge(value)
        elsif value.is_a?(Hash) || value.is_a?(Array) then tag.code(truncate(value.to_json, length: 80), class: "adm-code")
        else value.to_s
        end
      end
    end

    def boolean_badge(value)
      if value
        tag.span(t("administratum.yes"), class: "adm-badge adm-badge-success")
      else
        tag.span(t("administratum.no"), class: "adm-badge")
      end
    end

    # Links to the record's show page when a resource manages its model.
    def link_to_record(record)
      resource = Administratum.registry.for_model(record.class)
      return record_title(record) unless resource&.definition&.action_enabled?(:show) && resource.definition.parent.nil?

      link_to record_title(record), Administratum::Paths.new(resource, self).show(record)
    end

    def default_breadcrumbs
      crumbs = [[administratum_config.app_name, administratum.root_path]]
      return crumbs unless controller.is_a?(Administratum::Resource)

      if parent_record && (parent_resource = resource_class.parent_resource)
        parent_paths = Administratum::Paths.new(parent_resource, self)
        crumbs << [parent_resource.plural_label, (parent_paths.index if parent_resource.definition.action_enabled?(:index))]
        crumbs << [record_title(parent_record), parent_path]
      end
      index = collection_path if definition.action_enabled?(:index)
      crumbs << [resource_class.plural_label, index]
      crumbs << [record_title(@resource), (resource_path if definition.action_enabled?(:show))] if @resource&.persisted? && action_name != "show"
      crumbs
    end

    # Buttons for a page: built-ins (new, edit, delete…) followed by the
    # resource's custom buttons. `record` is required on :show, :edit and :row.
    def buttons_for(page, record = @resource)
      buttons = built_in_buttons(page.to_sym, record)
      buttons += definition.buttons_for(page).filter_map { |button| render_button(button, record) }
      safe_join(buttons, " ")
    end

    def render_button(button, record = @resource)
      return unless button_visible?(button, record)

      label = button.label || t("administratum.actions.#{button.name}", default: button.name.to_s.humanize)
      classes = BUTTON_STYLES.fetch(button.style, BUTTON_STYLES[:secondary])

      return panel_button(button, label, classes, record) if button.panel || button.upload

      url, http_method = button_target(button, record)
      administratum_button(label, url, method: http_method, confirm: button.confirm, class: classes)
    end

    # A link for GET, otherwise a one-button form (no rails-ujs needed).
    def administratum_button(label, url, method: :get, confirm: nil, **options)
      if method.to_sym == :get
        link_to label, url, **options
      else
        form = { data: confirm ? { adm_confirm: confirm } : {} }
        button_to label, url, method:, form:, form_class: "adm-inline-form", **options
      end
    end

    def filters?
      definition.filters.any? && @search
    end

    def filter_collection(filter)
      collection = filter.collection
      collection = instance_exec(&collection) if collection.respond_to?(:call)
      collection = collection.to_a if collection.is_a?(ActiveRecord::Relation)
      collection.map { |item| item.is_a?(ActiveRecord::Base) ? [record_title(item), item.id] : item }
    end

    private

    def built_in_buttons(page, record)
      buttons = []
      case page
      when :index
        buttons << link_to(t("administratum.actions.new", resource: resource_class.singular_label), new_resource_path, class: BUTTON_STYLES[:primary]) if definition.action_enabled?(:new)
      when :show
        buttons << link_to(t("administratum.actions.edit"), edit_resource_path(record), class: BUTTON_STYLES[:primary]) if definition.action_enabled?(:edit)
        buttons << delete_button(record) if definition.action_enabled?(:destroy)
      when :edit
        buttons << link_to(t("administratum.actions.view"), resource_path(record), class: BUTTON_STYLES[:secondary]) if definition.action_enabled?(:show)
        buttons << delete_button(record) if definition.action_enabled?(:destroy)
      when :row
        buttons << link_to(t("administratum.actions.view"), resource_path(record), class: "adm-btn adm-btn-ghost adm-btn-sm") if definition.action_enabled?(:show)
        buttons << link_to(t("administratum.actions.edit"), edit_resource_path(record), class: "adm-btn adm-btn-ghost adm-btn-sm") if definition.action_enabled?(:edit)
        buttons << delete_button(record, small: true) if definition.action_enabled?(:destroy)
      end
      buttons
    end

    def delete_button(record, small: false)
      administratum_button(t("administratum.actions.destroy"), resource_path(record), method: :delete,
                                                                                      confirm: t("administratum.confirm"),
                                                                                      class: class_names("adm-btn adm-btn-danger", "adm-btn-sm" => small))
    end

    def button_visible?(button, record)
      return true unless button.condition

      condition = button.condition
      condition.arity.zero? ? instance_exec(&condition) : instance_exec(record, &condition)
    end

    def button_target(button, record)
      if button.to
        url = button.to.arity.zero? ? instance_exec(&button.to) : instance_exec(record, &button.to)
        return [url, button.http_method || :get]
      end

      action = definition.custom_actions.fetch(button.action) do
        raise Administratum::Error, "Button :#{button.name} points at :#{button.action}, which is not a declared custom action"
      end
      [action_path(action.name, action.member? ? record : nil), button.http_method || action.http_method]
    end

    # Opens an offcanvas panel: either a custom partial, or a file upload form
    # posting to the button's action.
    def panel_button(button, label, classes, record)
      panel_id = "adm-panel-#{button.name}#{"-#{record.id}" if record&.persisted?}"
      content_for(:panels) do
        render "administratum/shared/panel", id: panel_id, title: label, button:, record:,
                                             target: (button_target(button, record).first unless button.panel)
      end
      tag.button(label, type: "button", class: classes, data: { adm_offcanvas_open: panel_id })
    end
  end
end
