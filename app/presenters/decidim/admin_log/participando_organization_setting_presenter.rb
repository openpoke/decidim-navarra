# frozen_string_literal: true

module Decidim
  module AdminLog
    # This class holds the logic to present a `ParticipandoOrganizationSetting`
    # for the `AdminLog` log.
    class ParticipandoOrganizationSettingPresenter < Decidim::Log::BasePresenter
      private

      def diff_fields_mapping
        {
          application: :string,
          user: :string,
          password: :string,
          encryption_key: :string
        }
      end

      def i18n_params
        super.merge(
          organization_name: translated_attribute(resource_presenter.send(:resource).organization.name)
        )
      end

      def action_string
        "decidim.admin_log.participando_organization_setting.update"
      end

      def i18n_labels_scope
        "activemodel.attributes.participando_organization_setting"
      end
    end
  end
end
