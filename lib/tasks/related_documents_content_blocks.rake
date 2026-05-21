# frozen_string_literal: true

namespace :decidim_navarra do
  desc "Activate or deactivate the 'related_documents' content block for each participatory space" \
       " based on whether it has document attachments"
  task sync_related_documents_content_blocks: :environment do
    manifests_with_related_documents = Decidim.participatory_space_manifests.select do |manifest|
      scope_name = manifest.content_blocks_scope_name
      next false if scope_name.blank?

      Decidim.content_blocks.for(scope_name).any? { |manifest| manifest.name == :related_documents }
    end

    if manifests_with_related_documents.empty?
      puts "No participatory space manifests have a 'related_documents' content block registered."
      next
    end

    Decidim::Organization.find_each do |organization|
      manifests_with_related_documents.each do |manifest|
        spaces = manifest.participatory_spaces.call(organization)
        scope_name = manifest.content_blocks_scope_name

        spaces.each do |space|
          has_documents = space.attachments.documents.exists?

          if has_documents
            RelatedDocumentsContentBlockSync.activate(organization:, scope_name:, resource: space)
            puts "Activated related_documents block for #{manifest.name} ##{space.id} (org ##{organization.id})"
          else
            RelatedDocumentsContentBlockSync.deactivate(organization:, scope_name:, resource: space)
            puts "Deactivated related_documents block for #{manifest.name} ##{space.id} (org ##{organization.id})"
          end
        end
      end
    end

    puts "Done."
  end
end
