# frozen_string_literal: true

module Administratum
  # Built-in management of admin users. Disable with config.manage_users = false.
  class UserAdmin < Administratum::Resource
    model Administratum::User
    title :email
    label "Admin", plural: "Admins"
    route :admin_users
    menu priority: 1000

    filters :email
    index sort: "email asc" do
      column :email
      column :created_at
    end

    form do
      field :email
      field :password
      field :password_confirmation, as: :password
    end

    show do
      attribute :email
      attribute :created_at
      attribute :updated_at
    end

    private

    # Leaving the password blank on edit keeps the current one.
    def resource_params
      attrs = super
      attrs = attrs.except(:password, :password_confirmation) if action_name == "update" && attrs[:password].blank?
      attrs
    end
  end
end
