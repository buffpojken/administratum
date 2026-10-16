# frozen_string_literal: true

class CreateBlog < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.timestamps
    end

    create_table :posts do |t|
      t.string :title, null: false
      t.text :body
      t.boolean :published, default: false, null: false
      t.references :category, foreign_key: true
      t.string :color
      t.json :metadata
      t.timestamps
    end

    create_table :comments do |t|
      t.references :post, null: false, foreign_key: true
      t.string :author
      t.text :body, null: false
      t.timestamps
    end

    create_table :attachments do |t|
      t.references :post, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end

    create_table :posts_tags, id: false do |t|
      t.references :post, null: false
      t.references :tag, null: false
    end

    create_table :tags do |t|
      t.string :name, null: false
      t.timestamps
    end
  end
end
