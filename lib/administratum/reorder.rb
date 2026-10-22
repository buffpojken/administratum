# frozen_string_literal: true

module Administratum
  # Puts records in order from a positions[id]=n payload.
  module Reorder
    module_function

    # Only records in `relation` move. Each submitted record is put at its
    # number among the others (ties keep the current order); records left out
    # keep their order around them. Positions are then renumbered from 1, and
    # changed records saved with update!, so validations and callbacks run.
    # Returns the records in their new order.
    def call(relation, positions, column: :position)
      positions = positions.to_unsafe_h if positions.respond_to?(:to_unsafe_h)
      positions = {} unless positions.is_a?(Hash)
      wanted = positions.to_h { |id, value| [id.to_s, Integer(value.to_s, exception: false)] }.compact

      moved, sorted = relation.reorder(column, relation.klass.primary_key).to_a.partition { |record| wanted.key?(record.id.to_s) }
      index = -1
      moved.sort_by.with_index { |record, current| [wanted[record.id.to_s], current] }.each do |record|
        index = (wanted[record.id.to_s] - 1).clamp(index + 1, sorted.size)
        sorted.insert(index, record)
      end

      relation.klass.transaction do
        sorted.each.with_index(1) do |record, position|
          record.update!(column => position) unless record.public_send(column) == position
        end
      end
      sorted
    end
  end
end
