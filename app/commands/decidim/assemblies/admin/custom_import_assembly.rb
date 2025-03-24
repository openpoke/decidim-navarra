# frozen_string_literal: true

module Decidim
  module Assemblies
    module Admin
      # A command with all the business logic when copying a new assembly
      # in the system.
      class CustomImportAssembly < ImportAssembly
        private

        def import_assembly
          importer = Decidim::Assemblies::AssemblyImporter.new(form.current_organization, form.current_user)

          assemblies.each do |original_assembly|
            title = multiple_assemblies? ? original_assembly.fetch("title", form.title) : form.title
            slug = multiple_assemblies? ? original_assembly.fetch("slug", form.slug) : form.slug
            @imported_assembly = importer.import(original_assembly, form.current_user, title:, slug:)
            importer.import_assemblies_type(original_assembly["decidim_assemblies_type_id"])
            importer.import_categories(original_assembly["assembly_categories"]) if form.import_categories?
            importer.import_folders_and_attachments(original_assembly["attachments"]) if form.import_attachments?
            importer.import_components(original_assembly["components"]) if form.import_components?
            @imported_assembly.update(decidim_area_id: original_assembly["decidim_area_id"])
            @imported_assembly.publish!
          end
        end

        def multiple_assemblies?
          assemblies.count > 1
        end
      end
    end
  end
end
