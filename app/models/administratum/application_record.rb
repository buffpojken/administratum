# frozen_string_literal: true

module Administratum
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
