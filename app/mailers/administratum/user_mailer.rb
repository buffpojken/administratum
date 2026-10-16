# frozen_string_literal: true

module Administratum
  class UserMailer < ApplicationMailer
    def reset_password
      @user = params[:user]
      @url = administratum.edit_password_reset_url(token: params[:token])
      mail to: @user.email, subject: t("administratum.password_resets.subject", app: Administratum.config.app_name)
    end
  end
end
