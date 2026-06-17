# Multiselect for street verificator
Decidim::Verifications.register_workflow(:census_authorization_handler) do |workflow|
  workflow.form = "CensusAuthorizationHandler"
  workflow.renewable = true
  workflow.time_between_renewals = 5.minutes
end
