# frozen_string_literal: true

class RenameApplicationToEntityNifInParticipandoOrganizationSettings < ActiveRecord::Migration[7.2]
  def change
    rename_column :participando_organization_settings, :application, :entity_nif
  end
end
