# frozen_string_literal: true

class CreateParticipandoOrganizationSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :participando_organization_settings do |t|
      t.references :decidim_organization, null: false, foreign_key: true, index: { unique: true }

      t.text :application, null: false
      t.text :user, null: false
      t.text :password, null: false
      t.text :encryption_key, null: false

      t.timestamps
    end
  end
end