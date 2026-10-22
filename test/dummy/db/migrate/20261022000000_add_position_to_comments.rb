# frozen_string_literal: true

class AddPositionToComments < ActiveRecord::Migration[8.0]
  def change
    add_column :comments, :position, :integer
  end
end
