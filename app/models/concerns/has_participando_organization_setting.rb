# frozen_string_literal: true

module HasParticipandoOrganizationSetting
  extend ActiveSupport::Concern

  included do
    has_one :participando_organization_setting, class_name: "ParticipandoOrganizationSetting", foreign_key: :decidim_organization_id, dependent: :destroy
  end
end
