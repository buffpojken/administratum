# frozen_string_literal: true

module Administratum
  module FormHelper
    # form_with pointed at the right URL and method for the record, whether it
    # is new or persisted, nested or not. Use it in custom form templates.
    def administratum_form(record = @resource, **options, &)
      options[:class] = class_names("adm-form", options[:class])
      form_with(model: record, scope: record.model_name.param_key, url: resource_form_path(record),
                method: record.persisted? ? :patch : :post, **options, &)
    end

    # Renders the DSL's form fields, or the subset named in `only`.
    def render_fields(form, only: nil, except: nil)
      fields = definition.fields
      fields = fields.select { |field| Array(only).map(&:to_sym).include?(field.name) } if only
      fields = fields.reject { |field| Array(except).map(&:to_sym).include?(field.name) } if except
      safe_join(fields.map { |field| render_field(form, field) })
    end

    # Renders one field with its label, hint and errors. Pass a name declared
    # in the DSL, or a name plus `as:` and options for an ad-hoc field.
    def render_field(form, field, as: nil, **options)
      field = resolve_field(form, field, as:, options:)
      type = Administratum.field_types.fetch(field.type)
      locals = { form:, field:, resource: form.object, value: form.object.try(field.name) }
      input = render(partial: type.partial, locals:)
      return input if field.type == :hidden || field.options[:wrapper] == false

      render "administratum/fields/wrapper", locals.merge(input:)
    end

    # "tag_ids" reads as "Tags"; "category_id" is already "Category" in Rails.
    def field_label(form, field)
      return field.label if field.label

      name = field.name.to_s
      name = name.delete_suffix("_ids").pluralize if name.end_with?("_ids")
      form.object.class.human_attribute_name(name)
    end

    # `required:` on the field wins; otherwise a presence validation marks it.
    def field_required?(form, field)
      field.options.fetch(:required) do
        model = form.object.class
        return false unless model.respond_to?(:validators_on)

        attributes = [field.name, field.name.to_s.delete_suffix("_id").to_sym].uniq
        attributes.any? { |attribute| model.validators_on(attribute).any?(ActiveModel::Validations::PresenceValidator) }
      end
    end

    def field_errors(form, field)
      attribute = field.name.to_s.delete_suffix("_id").delete_suffix("_ids")
      (form.object.errors[field.name] + form.object.errors[attribute.to_sym]).uniq
    end

    # Options for select-style fields. `collection` may be an array, a
    # relation, or a lambda (optionally receiving the record).
    def field_collection(field, record)
      collection = field.options[:collection]
      collection = collection.arity.zero? ? instance_exec(&collection) : instance_exec(record, &collection) if collection.respond_to?(:call)
      collection ||= association_collection(field, record)
      collection = collection.to_a if collection.is_a?(ActiveRecord::Relation)
      collection.map { |item| item.is_a?(ActiveRecord::Base) ? [record_title(item), item.id] : item }
    end

    # HTML options for a field's input: the partial's defaults, then the
    # field's placeholder and hint wiring, then its input_html overrides.
    def input_options(field, form: nil, **defaults)
      defaults[:placeholder] = field.options[:placeholder] if field.options[:placeholder]
      defaults[:aria] = { describedby: form.field_id(field.name, :hint) } if field.hint && form
      defaults.merge(field.options.fetch(:input_html, {}))
    end

    private

    def resolve_field(form, field, as:, options:)
      return field if field.is_a?(Administratum::Definition::Field)

      declared = definition.field(field) if respond_to?(:definition)
      return declared.dup.tap { |copy| copy.options = copy.options.merge(options) } if declared && as.nil?

      type = (as || Administratum.field_types.infer(form.object.class, field)).to_sym
      Administratum::Definition::Field.new(name: field.to_sym, type:, options:)
    end

    def association_collection(field, record)
      name = field.name.to_s.delete_suffix("_ids").delete_suffix("_id")
      reflection = record.class.reflect_on_association(name.to_sym) || record.class.reflect_on_association(name.pluralize.to_sym)
      reflection ? reflection.klass.all : []
    end
  end
end
