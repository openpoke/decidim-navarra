# frozen_string_literal: true

module Decidim
  module ParticipatoryProcesses
    # A factory class to ensure we always create ParticipatoryProcesses the same way since it involves some logic.
    class CustomParticipatoryProcessImporter < ParticipatoryProcessImporter
      def import(attributes, _user, opts)
        title = opts[:title]
        slug = opts[:slug]
        Decidim.traceability.perform_action!(:create, ParticipatoryProcess, @user, visibility: "all") do
          @imported_process = ParticipatoryProcess.new(
            organization: @organization,
            title: title,
            slug: slug,
            subtitle: attributes["subtitle"],
            hashtag: attributes["hashtag"],
            description: attributes["description"],
            short_description: attributes["short_description"],
            promoted: attributes["promoted"],
            developer_group: attributes["developer_group"],
            local_area: attributes["local_area"],
            target: attributes["target"],
            participatory_scope: attributes["participatory_scope"],
            participatory_structure: attributes["participatory_structure"],
            meta_scope: attributes["meta_scope"],
            start_date: attributes["start_date"],
            end_date: attributes["end_date"],
            announcement: attributes["announcement"],
            private_space: attributes["private_space"],
            scopes_enabled: attributes["scopes_enabled"],
            participatory_process_group: import_process_group(attributes["participatory_process_group"])
          )
          @imported_process.remote_hero_image_url = attributes["remote_hero_image_url"] if remote_file_exists?(attributes["remote_hero_image_url"])
          @imported_process.remote_banner_image_url = attributes["remote_banner_image_url"] if remote_file_exists?(attributes["remote_banner_image_url"])
          @imported_process.decidim_scope_id = attributes["scope"]["id"]
          @imported_process.decidim_area_id = attributes["area"]["id"]
          @imported_process.save!
          @imported_process.update_attribute(:created_at, attributes["start_date"])
          @imported_process.publish!
          @imported_process
        end
      end

      def import_process_group(attributes)
        return if attributes.blank?

        super
      end
    end
  end
end
