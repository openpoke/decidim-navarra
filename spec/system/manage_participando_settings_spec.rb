# frozen_string_literal: true

require "rails_helper"

describe "ManageParticipandoSettings", perform_enqueued: true do
  let(:admin) { Decidim::System::Admin.create!(email: "system-admin@example.org", password: "password123456", password_confirmation: "password123456") }
  let(:organization) { create(:organization) }

  before do
    login_as admin, scope: :admin
  end

  describe "visiting participando settings index" do
    it "shows the participando settings page" do
      visit decidim_system.participando_organization_settings_path

      expect(page).to have_content(I18n.t("decidim.system.participando_organization_settings.index.title"))
    end

    it "lists all organizations" do
      other_organization = create(:organization)

      visit decidim_system.participando_organization_settings_path

      expect(page).to have_content(organization.host)
      expect(page).to have_content(other_organization.host)
    end

    context "when organization has a participando setting" do
      let!(:setting) do
        create(:participando_organization_setting,
               organization:,
               application: "test_app")
      end

      it "shows the application identifier" do
        visit decidim_system.participando_organization_settings_path

        expect(page).to have_content("test_app")
      end

      it "shows the updated date" do
        visit decidim_system.participando_organization_settings_path

        expect(page).to have_content(setting.updated_at.strftime("%d/%m/%Y"))
      end
    end

    context "when organization does not have a participando setting" do
      it "shows no settings message" do
        visit decidim_system.participando_organization_settings_path

        expect(page).to have_content(I18n.t("decidim.system.participando_organization_settings.index.no_settings"))
      end
    end
  end

  describe "editing participando settings" do
    context "when creating a new setting" do
      it "loads the edit form" do
        visit decidim_system.edit_participando_organization_setting_path(organization)

        expect(page).to have_content(I18n.t("decidim.system.participando_organization_settings.edit.title"))
      end

      it "has empty form fields" do
        visit decidim_system.edit_participando_organization_setting_path(organization)

        expect(page).to have_field("participando_organization_setting_application", with: "")
        expect(page).to have_field("participando_organization_setting_user", with: "")
        expect(page).to have_field("participando_organization_setting_password", with: "")
        expect(page).to have_field("participando_organization_setting_encryption_key", with: "")
      end

      it "creates a new setting" do
        visit decidim_system.edit_participando_organization_setting_path(organization)

        fill_in "participando_organization_setting_application", with: "new_app"
        fill_in "participando_organization_setting_user", with: "new_user"
        fill_in "participando_organization_setting_password", with: "new_password"
        fill_in "participando_organization_setting_encryption_key", with: "new_key"

        click_button I18n.t("decidim.system.participando_organization_settings.edit.save")

        expect(page).to have_content(I18n.t("decidim.system.participando_organization_settings.update.success"))
        expect(organization.reload.participando_organization_setting).to be_present
        expect(organization.participando_organization_setting.application).to eq("new_app")
      end
    end

    context "when updating an existing setting" do
      let!(:setting) do
        create(:participando_organization_setting,
               organization:,
               application: "old_app",
               user: "old_user",
               password: "old_password",
               encryption_key: "old_key")
      end

      it "loads the edit form with existing data" do
        visit decidim_system.edit_participando_organization_setting_path(organization)

        expect(page).to have_field("participando_organization_setting_application", with: "old_app")
        expect(page).to have_field("participando_organization_setting_user", with: "old_user")
        expect(page).to have_field("participando_organization_setting_password", with: "old_password")
        expect(page).to have_field("participando_organization_setting_encryption_key", with: "old_key")
      end

      it "updates the setting" do
        visit decidim_system.edit_participando_organization_setting_path(organization)

        fill_in "participando_organization_setting_application", with: "updated_app"
        click_button I18n.t("decidim.system.participando_organization_settings.edit.save")

        expect(page).to have_content(I18n.t("decidim.system.participando_organization_settings.update.success"))
        expect(setting.reload.application).to eq("updated_app")
      end
    end

    context "when submitting invalid data" do
      it "shows an error when application is empty" do
        visit decidim_system.edit_participando_organization_setting_path(organization)

        fill_in "participando_organization_setting_application", with: ""
        fill_in "participando_organization_setting_user", with: "user"
        fill_in "participando_organization_setting_password", with: "password"
        fill_in "participando_organization_setting_encryption_key", with: "key"

        click_button I18n.t("decidim.system.participando_organization_settings.edit.save")

        expect(page).to have_content(I18n.t("decidim.forms.errors.error"))
      end

      it "shows an error when required fields are missing" do
        visit decidim_system.edit_participando_organization_setting_path(organization)

        click_button I18n.t("decidim.system.participando_organization_settings.edit.save")

        expect(page).to have_content(I18n.t("decidim.forms.errors.error"))
      end
    end
  end

  describe "navigating from index to edit" do
    it "can navigate to edit from index" do
      visit decidim_system.participando_organization_settings_path

      click_link "Edit"

      expect(page).to have_current_path(decidim_system.edit_participando_organization_setting_path(organization))
    end
  end
end
