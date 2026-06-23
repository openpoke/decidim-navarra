# frozen_string_literal: true

require "decidim/core/test/factories"
require "decidim/decidim_awesome/test/factories"

FactoryBot.define do
  factory :participando_organization_setting do
    organization
    entity_nif { "B00000000" }
    user { "test_user" }
    password { "test_password" }
    encryption_key { "12345678901234567890123456789012" }
  end

  trait :with_participando_setting do
    after(:create) do |organization|
      create(:participando_organization_setting, organization: organization)
    end
  end
end
