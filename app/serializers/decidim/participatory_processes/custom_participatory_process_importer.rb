# frozen_string_literal: true

module Decidim
  module ParticipatoryProcesses
    # A factory class to ensure we always create ParticipatoryProcesses the same way since it involves some logic.
    class CustomParticipatoryProcessImporter < ParticipatoryProcessImporter
      def import(attributes, _user, opts)
        title = opts[:title]
        slug = opts[:slug]
        Decidim.traceability.perform_action!(:create, ParticipatoryProcess, @user, visibility: 'all') do
          @imported_process = ParticipatoryProcess.new(
            organization: @organization,
            title:,
            slug:,
            subtitle: attributes['subtitle'],
            hashtag: attributes['hashtag'],
            description: attributes['description'],
            short_description: attributes['short_description'],
            promoted: attributes['promoted'],
            developer_group: attributes['developer_group'],
            local_area: attributes['local_area'],
            target: attributes['target'],
            participatory_scope: attributes['participatory_scope'],
            participatory_structure: attributes['participatory_structure'],
            meta_scope: attributes['meta_scope'],
            start_date: attributes['start_date'],
            end_date: attributes['end_date'],
            announcement: attributes['announcement'],
            private_space: false,
            scopes_enabled: attributes['scopes_enabled'],
            participatory_process_type: participatory_process_type(attributes['decidim_participatory_process_type_id']),
            participatory_process_group: import_process_group(attributes['participatory_process_group'])
          )
          @imported_process.decidim_scope_id = attributes['scope']['id']
          @imported_process.decidim_area_id = attributes['area']['id']
          @imported_process.save!
          %i[hero_image banner_image].each do |attr|
            upload_attachment(attr, attributes["remote_#{attr}_url"])
          end
          @imported_process.update(created_at: attributes['start_date'])
          @imported_process.publish!
          @imported_process
        end
      rescue ActiveRecord::RecordInvalid
        errors = @imported_process.errors.full_messages.join("\n")
        Rails.logger.error(
          "Pocess with id #{@imported_process.id} and slug #{@imported_process.slug} has validation errors:\n #{errors}"
        )
        @imported_process
      end

      def import_process_group(attributes)
        return if attributes.blank?

        ParticipatoryProcessGroup.find_by(
          title: attributes['title'],
          description: attributes['description'],
          organization: @organization
        )
      end

      def participatory_process_type(id)
        return if id.blank?

        ::Decidim::ParticipatoryProcessType.find_by(
          id:
        )
      end

      require 'net/http'
      require 'open-uri'

      def upload_attachment(attribute, url)
        return unless url.present? && remote_file_exists?(url)

        uri = URI.parse(url)
        file = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.get(uri.path)
        end

        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new(file.body),
          filename: File.basename(uri.path)
        )
        blob.analyze
        @imported_process.send(attribute).attach(blob)
      end
    end
  end
end
