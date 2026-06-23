# frozen_string_literal: true

module Decidim
  module System
    # Controller that allows managing all the Admins.
    #
    class ParticipandoOrganizationSettingsController < Decidim::System::ApplicationController
      helper_method :organizations, :current_organization, :current_setting
      def index; end

      def edit
        @form = form(ParticipandoOrganizationSettingForm).from_model(current_setting)
      end

      def update
        @form = form(ParticipandoOrganizationSettingForm).from_params(params, current_organization: current_organization)

        UpdateParticipandoOrganizationSetting.call(@form, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("decidim.system.participando_organization_settings.update.success")
            redirect_to action: :index
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("decidim.system.participando_organization_settings.update.error")
            render :edit, status: :unprocessable_entity
          end
        end
      end

      private

      def organizations
        @organizations ||= Decidim::Organization.includes(:participando_organization_setting).all
      end

      def current_setting
        @setting ||= current_organization.participando_organization_setting || current_organization.build_participando_organization_setting
      end

      def current_organization
        Decidim::Organization.find(params[:id])
      end
    end
  end
end
