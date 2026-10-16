# frozen_string_literal: true

module Administratum
  class User < ApplicationRecord
    self.table_name = "administratum_users"

    devise :database_authenticatable, :recoverable, :rememberable, :validatable

    def to_s
      email
    end
  end
end
