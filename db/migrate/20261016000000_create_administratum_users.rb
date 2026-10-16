# frozen_string_literal: true

class CreateAdministratumUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :administratum_users do |t|
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.timestamps
    end

    add_index :administratum_users, :email, unique: true
    add_index :administratum_users, :reset_password_token, unique: true
  end
end
