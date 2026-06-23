# frozen_string_literal: true

require "rails_helper"

RSpec.describe Decidim::AdminLog::ParticipandoOrganizationSettingPresenter do
  subject(:presenter) { described_class.new(action_log, view_helpers) }

  let(:action_log) do
    instance_double(
      Decidim::ActionLog,
      action: "update",
      participatory_space: nil,
      extra: {},
      version: nil,
      user: nil,
      resource: nil,
      created_at: Time.current
    )
  end
  let(:view_helpers) { double("view_helpers") }

  describe "private helpers" do
    it "uses the participando organization setting labels" do
      expect(presenter.send(:i18n_labels_scope)).to eq("activemodel.attributes.participando_organization_setting")
    end

    it "limits the diff to the configurable attributes" do
      expect(presenter.send(:diff_fields_mapping)).to eq(
        application: :string,
        user: :string,
        password: :string,
        encryption_key: :string
      )
    end
  end
end
