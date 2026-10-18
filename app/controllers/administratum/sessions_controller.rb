# frozen_string_literal: true

module Administratum
  class SessionsController < ApplicationController
    # remember_me lives here; Devise only mixes it into its own controllers.
    include Devise::Controllers::Rememberable

    layout "administratum/authentication"

    skip_before_action :authenticate_admin!, only: %i[new create]

    def new; end

    def create
      user = Administratum::User.find_for_authentication(email: params[:email].to_s)

      if user&.valid_for_authentication? { user.valid_password?(params[:password].to_s) } && user.active_for_authentication?
        sign_in(:administratum_user, user)
        remember_me(user) if params[:remember_me] == "1"
        redirect_to stored_location_for(:administratum_user) || administratum.root_path
      else
        flash.now[:alert] = t("administratum.sessions.invalid")
        render :new, status: :unprocessable_content
      end
    end

    # Signs out only the admin scope, so a host app session survives.
    def destroy
      sign_out(:administratum_user)
      redirect_to administratum.sign_in_path, notice: t("administratum.sessions.signed_out")
    end
  end
end
