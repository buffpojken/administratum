# frozen_string_literal: true

Rails.application.routes.draw do
  mount Administratum::Engine => "/administratum"

  # Lets tests put a host-app value in the session.
  get "host_session", to: ->(env) { env["rack.session"][:host_value] = "kept"; [200, {}, ["ok"]] }
end
