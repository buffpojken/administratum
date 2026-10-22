# frozen_string_literal: true

module Administratum
  # Controls for putting records in order. Mark the list's container with
  # data-adm-sortable and each record's element with data-adm-sortable-item,
  # put reorder_controls in each, and submit them with reorder_form and
  # reorder_save_button:
  #
  #   <%= reorder_form id: "chapter-order", url: action_path(:reorder) %>
  #   <ol data-adm-sortable>
  #     <% chapters.each do |chapter| %>
  #       <li data-adm-sortable-item><%= reorder_controls chapter, form: "chapter-order" %> <%= chapter.title %></li>
  #     <% end %>
  #   </ol>
  #   <%= reorder_save_button form: "chapter-order" %>
  module ReorderHelper
    # An empty form. The position fields and the save button join it through
    # their form="…" attribute, so the list can sit anywhere, even around rows
    # that hold forms of their own.
    def reorder_form(id:, url:, method: :patch)
      form_with(url:, method:, id:, class: "adm-reorder-form") { "" }
    end

    # A drag handle and move up/down buttons, shown by administratum.js, and
    # the positions[id] number field they keep up to date. Without JS only the
    # number field shows.
    def reorder_controls(record, form:, column: :position, position: record.public_send(column))
      input_id = "#{form}-position-#{record.id}"
      fallback = tag.span(data: { adm_sortable_fallback: true }) do
        label_tag(input_id, t("administratum.reorder.position"), class: "adm-sr-only") +
          number_field_tag("positions[#{record.id}]", position, id: input_id, form:, min: 1,
                                                                class: "adm-input adm-sortable-position", data: { adm_sortable_position: true })
      end

      tag.span(class: "adm-sortable-controls", data: { adm_sortable_moved: t("administratum.reorder.moved") }) do
        safe_join([
                    reorder_button("⠿", :handle, class: "adm-icon-btn adm-sortable-handle", data: { adm_sortable_handle: true }),
                    reorder_button("↑", :up, class: "adm-icon-btn", data: { adm_sortable_up: true }),
                    reorder_button("↓", :down, class: "adm-icon-btn", data: { adm_sortable_down: true }),
                    fallback
                  ])
      end
    end

    def reorder_save_button(form:, label: t("administratum.reorder.save"), **options)
      tag.button(label, **options.except(:class), type: "submit", form:, class: class_names("adm-btn adm-btn-primary", options[:class]))
    end

    private

    def reorder_button(symbol, name, **)
      tag.button(symbol, type: "button", hidden: true, aria: { label: t("administratum.reorder.#{name}") }, **)
    end
  end
end
