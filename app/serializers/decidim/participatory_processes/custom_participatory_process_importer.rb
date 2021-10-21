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
            private_space: false,
            scopes_enabled: attributes["scopes_enabled"],
            participatory_process_group: import_process_group(attributes["participatory_process_group"])
          )
          @imported_process.decidim_scope_id = attributes["scope"]["id"]
          @imported_process.decidim_area_id = attributes["area"]["id"]
          @imported_process.save!
          [:hero_image, :banner_image].each do |attr|
            next unless remote_file_exists?(attributes["remote_#{attr}_url"])
            file = URI.open(attributes["remote_#{attr}_url"])
            uri = URI.parse(attributes["remote_#{attr}_url"])
            @imported_process.send(attr).attach(io: file, filename: File.basename(uri.path))
          end
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
