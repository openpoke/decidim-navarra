# frozen_string_literal: true

module Decidim
  module System
    class UpdateParticipandoOrganizationSetting < Decidim::Command
      def initialize(form, user)
        @form = form
        @user = user
      end

      attr_reader :form, :user

      def call
        return broadcast(:invalid) if form.invalid?

        @setting = Decidim.traceability.update!(
          setting,
          user,
          application: form.application,
          user: form.user,
          password: form.password,
          encryption_key: form.encryption_key
        )

        broadcast(:ok)
      end

      private

      def organization
        @form.current_organization
      end

      def setting
        organization.participando_organization_setting || organization.build_participando_organization_setting
      end
    end
  end
end
