# frozen_string_literal: true

# Multiselect for street verificator
Decidim::Verifications.register_workflow(:participando_authorization_handler) do |workflow|
  workflow.form = "ParticipandoAuthorizationHandler"
  workflow.renewable = true
  workflow.time_between_renewals = 5.minutes
end
