# frozen_string_literal: true

module Decidim
  module ParticipatoryProcesses
    module Admin
      # A command with all the business logic when copying a new participatory
      # process in the system.
      class CustomImportParticipatoryProcess < ImportParticipatoryProcess
        private

        def import_participatory_process
          importer = Decidim::ParticipatoryProcesses::CustomParticipatoryProcessImporter.new(form.current_organization, form.current_user)

          participatory_processes.each do |original_process|
            title = multiple_processes? ? original_process.fetch("title", form.title) : form.title
            slug = multiple_processes? ? original_process.fetch("slug", form.slug) : form.slug
            @imported_process = importer.import(original_process, form.current_user, title: title, slug: slug)
            importer.import_participatory_process_steps(original_process["participatory_process_steps"]) if form.import_steps?
            importer.import_categories(original_process["participatory_process_categories"]) if form.import_categories?
            importer.import_folders_and_attachments(original_process["attachments"]) if form.import_attachments?
            importer.import_components(original_process["components"]) if form.import_components?
          end
        end

        def multiple_processes?
          participatory_processes.count > 1
        end
      end
    end
  end
end
