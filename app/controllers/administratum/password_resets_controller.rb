# frozen_string_literal: true

module Administratum
  class PasswordResetsController < ApplicationController
    layout "administratum/authentication"

    skip_before_action :authenticate_admin!

    def new; end

    # Responds the same whether or not the address exists, so the form can't
    # be used to discover admin emails.
    def create
      user = Administratum::User.find_for_authentication(email: params[:email].to_s)
      if user
        token = user.send(:set_reset_password_token)
        Administratum::UserMailer.with(user:, token:).reset_password.deliver_later
      end
      redirect_to administratum.sign_in_path, notice: t("administratum.password_resets.sent")
    end

    def edit
      @token = params[:token]
    end

    def update
      @token = params[:token]
      user = Administratum::User.reset_password_by_token(
        reset_password_token: @token,
        password: params[:password],
        password_confirmation: params[:password_confirmation]
      )

      if user.errors.empty?
        redirect_to administratum.sign_in_path, notice: t("administratum.password_resets.updated")
      else
        @errors = user.errors.full_messages
        render :edit, status: :unprocessable_content
      end
    end
  end
end
