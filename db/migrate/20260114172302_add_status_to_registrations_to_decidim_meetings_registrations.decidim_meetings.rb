# frozen_string_literal: true

# This migration comes from decidim_meetings (originally 20250408071941)
class AddStatusToRegistrationsToDecidimMeetingsRegistrations < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_meetings_registrations, :status, :string, default: "registered" unless column_exists?(:decidim_meetings_registrations, :status)
    add_index :decidim_meetings_registrations, :status unless index_exists?(:decidim_meetings_registrations, :status)
  end
end
