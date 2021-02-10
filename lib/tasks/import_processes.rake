# frozen_string_literal: true

namespace :decidim_navarra do
  desc "Transforms a CSV of processes and imports it in a organization"
  task :import, [:csv_path, :organization_id, :admin_id] => [:environment] do |_t, args|
    raise "Please, provide a file path" if args[:csv_path].blank?

    organization = Decidim::Organization.find_by(id: args[:organization_id]) || Decidim::Organization.first
    admin = args[:admin_id].present? ? organization.admins.find_by(id: args[:admin_id]) : organization.admins.first

    puts "Importing processes, please wait..."
    importer = ProcessesImporter.new(args[:csv_path], organization, admin)
    importer.import_processes
    puts "Import completed."
  end
end
