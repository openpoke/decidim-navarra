# frozen_string_literal: true

module Decidim
  module System
    # A form object to be inherited to create and update organizations from the system dashboard.
    #
    class ParticipandoOrganizationSettingForm < Form
      mimic :participando_organization_setting

      attribute :application, String
      attribute :user, String
      attribute :password, String
      attribute :encryption_key, String

      validates :application, :user, :password, :encryption_key, presence: true
    end
  end
end
