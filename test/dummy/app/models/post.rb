# frozen_string_literal: true

class Post < ApplicationRecord
  belongs_to :category, optional: true
  has_many :comments, dependent: :destroy
  has_many :attachments, dependent: :destroy
  has_and_belongs_to_many :tags

  validates :title, presence: true

  scope :drafts, -> { where(published: false) }

  def self.export_json
    all.map { |post| post.slice(:title, :body, :published) }.to_json
  end

  def self.import_json(json)
    JSON.parse(json).each { |attrs| create!(attrs.slice("title", "body", "published")) }.size
  end
end
