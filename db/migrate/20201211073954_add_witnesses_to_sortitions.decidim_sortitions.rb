# frozen_string_literal:  true

# This migration comes from decidim_sortitions (originally 20171220164658)
# This file has been modified by `decidim upgrade:migrations` task on 2026-01-07 14:30:05 UTC
class AddWitnessesToSortitions < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_module_sortitions_sortitions, :witnesses, :jsonb
  end
end
