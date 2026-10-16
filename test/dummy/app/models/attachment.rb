# frozen_string_literal: true

class Attachment < ApplicationRecord
  belongs_to :post
  validates :name, presence: true
end
