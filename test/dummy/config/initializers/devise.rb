# frozen_string_literal: true

Devise.setup do |config|
  config.mailer_sender = "admin@example.com"
  config.stretches = Rails.env.test? ? 1 : 12
end
