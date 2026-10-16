# frozen_string_literal: true

module Administratum
  class ApplicationMailer < ActionMailer::Base
    default from: -> { Administratum.config.mailer_sender }
    layout false
  end
end
