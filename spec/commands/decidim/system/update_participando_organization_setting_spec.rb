# frozen_string_literal: true

require "rails_helper"

RSpec.describe Decidim::System::UpdateParticipandoOrganizationSetting do
  subject(:command) { described_class.new(form, user) }

  let(:user) { create(:user, :admin, organization: organization) }
  let(:organization) { create(:organization) }

  let(:form) do
    Decidim::System::ParticipandoOrganizationSettingForm.from_params(form_params).with_context(
      current_organization: organization
    )
  end

  let(:form_params) do
    {
      application: "new_app",
      user: "new_user",
      password: "new_password",
      encryption_key: "new_encryption_key"
    }
  end

  describe "call" do
    context "when form is valid" do
      context "when setting does not exist" do
        it "broadcasts ok" do
          expect { command.call }.to broadcast(:ok)
        end

        it "creates a new ParticipandoOrganizationSetting" do
          expect do
            command.call
          end.to change(ParticipandoOrganizationSetting, :count).by(1)
        end

        it "sets the correct attributes" do
          command.call
          setting = organization.participando_organization_setting
          expect(setting.application).to eq("new_app")
          expect(setting.user).to eq("new_user")
          expect(setting.password).to eq("new_password")
          expect(setting.encryption_key).to eq("new_encryption_key")
        end
      end

      context "when setting already exists" do
        let!(:existing_setting) do
          create(:participando_organization_setting,
                 organization: organization,
                 application: "old_app",
                 user: "old_user",
                 password: "old_password",
                 encryption_key: "old_encryption_key")
        end

        it "broadcasts ok" do
          expect { command.call }.to broadcast(:ok)
        end

        it "does not create a new ParticipandoOrganizationSetting" do
          expect do
            command.call
          end.not_to change(ParticipandoOrganizationSetting, :count)
        end

        it "updates the existing setting" do
          command.call
          existing_setting.reload
          expect(existing_setting.application).to eq("new_app")
          expect(existing_setting.user).to eq("new_user")
          expect(existing_setting.password).to eq("new_password")
          expect(existing_setting.encryption_key).to eq("new_encryption_key")
        end
      end
    end

    context "when form is invalid" do
      let(:form_params) do
        {
          application: nil,
          user: "new_user",
          password: "new_password",
          encryption_key: "new_encryption_key"
        }
      end

      it "broadcasts invalid" do
        expect { command.call }.to broadcast(:invalid)
      end

      it "does not create or update a setting" do
        expect do
          command.call
        end.not_to change(ParticipandoOrganizationSetting, :count)
      end
    end
  end
end
