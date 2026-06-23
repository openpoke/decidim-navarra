# frozen_string_literal: true

# ParticipandoAuthorizationHandler is a custom authorization handler that checks if a user is registered in the municipal census (padrón) using the ANIMSA-PMH web service.
# It validates the user's personal information and document details against the census records to determine if they are authorized.
# Requires to configure certain values in the /system panel for the organization, such as entity NIF, user credentials, and encryption keys.
Decidim::Verifications.register_workflow(:participando_authorization_handler) do |workflow|
  workflow.form = "ParticipandoAuthorizationHandler"
  workflow.renewable = true
  workflow.time_between_renewals = 5.minutes
end

# Admin menu
Decidim.menu :system_menu do |menu|
  menu.add_item :participando,
                I18n.t("decidim.participando_authorization_handler.system_name"),
                Decidim::System::Engine.routes.url_helpers.participando_organization_settings_path,
                position: 4,
                active: :inclusive
end

Rails.application.config.to_prepare do
  Decidim::Organization.include HasParticipandoOrganizationSetting
end
