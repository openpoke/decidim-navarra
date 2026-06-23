# frozen_string_literal: true

class ParticipandoOrganizationSetting < ApplicationRecord
  include Decidim::Traceable
  include Decidim::RecordEncryptor

  belongs_to :organization,
             class_name: "Decidim::Organization",
             foreign_key: :decidim_organization_id,
             inverse_of: :participando_organization_setting

  encrypt_attribute :entity_nif, type: :text
  encrypt_attribute :user, type: :text
  encrypt_attribute :password, type: :text
  encrypt_attribute :encryption_key, type: :text

  validates :decidim_organization_id, uniqueness: true
  validates :entity_nif, :user, :password, :encryption_key, presence: true

  def self.log_presenter_class_for(_log)
    Decidim::AdminLog::ParticipandoOrganizationSettingPresenter
  end
end
