# frozen_string_literal: true

require "decidim/core/test/factories"
require "decidim/decidim_awesome/test/factories"

FactoryBot.define do
  factory :participando_organization_setting do
    organization
    application { "test_application" }
    user { "test_user" }
    password { "test_password" }
    encryption_key { "test_encryption_key" }
  end
end
