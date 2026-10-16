# frozen_string_literal: true

module Administratum
  class ApplicationController < Administratum.config.parent_controller.constantize
    protect_from_forgery with: :exception

    layout "administratum/application"

    helper Administratum::ApplicationHelper
    Administratum.config.helpers.each { |mod| helper mod }

    before_action :authenticate_admin!

    helper_method :current_admin

    private

    def current_admin
      current_administratum_user
    end

    # Not Devise's authenticate_*! helper: that redirects through Devise's
    # failure app, which assumes Devise's own routes and controllers.
    def authenticate_admin!
      return if warden.authenticate(scope: :administratum_user)

      store_location_for(:administratum_user, request.fullpath) if request.get? && is_navigational_format?
      redirect_to administratum.sign_in_path, alert: t("administratum.sessions.unauthenticated")
    end
  end
end
