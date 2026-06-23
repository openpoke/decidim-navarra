# frozen_string_literal: true

require "rails_helper"

RSpec.describe Decidim::System::ParticipandoOrganizationSettingForm do
  subject(:form) { described_class.from_params(attributes) }

  let(:attributes) do
    {
      entity_nif: "B12345678",
      user: "test_user",
      password: "test_password",
      encryption_key: "test_encryption_key"
    }
  end

  describe "validations" do
    context "when all required attributes are present" do
      it { is_expected.to be_valid }
    end

    context "when entity_nif is missing" do
      before { attributes.delete(:entity_nif) }

      it { is_expected.to be_invalid }

      it "adds an error for entity_nif" do
        form.valid?
        expect(form.errors[:entity_nif]).not_to be_empty
      end
    end

    context "when user is missing" do
      before { attributes.delete(:user) }

      it { is_expected.to be_invalid }

      it "adds an error for user" do
        form.valid?
        expect(form.errors[:user]).not_to be_empty
      end
    end

    context "when password is missing" do
      before { attributes.delete(:password) }

      it { is_expected.to be_invalid }

      it "adds an error for password" do
        form.valid?
        expect(form.errors[:password]).not_to be_empty
      end
    end

    context "when encryption_key is missing" do
      before { attributes.delete(:encryption_key) }

      it { is_expected.to be_invalid }

      it "adds an error for encryption_key" do
        form.valid?
        expect(form.errors[:encryption_key]).not_to be_empty
      end
    end

    context "when multiple required attributes are missing" do
      before do
        attributes.delete(:entity_nif)
        attributes.delete(:password)
      end

      it { is_expected.to be_invalid }

      it "adds errors for missing attributes" do
        form.valid?
        expect(form.errors[:entity_nif]).not_to be_empty
        expect(form.errors[:password]).not_to be_empty
      end
    end
  end

  describe "attributes" do
    it "has entity_nif attribute" do
      expect(form.entity_nif).to eq("B12345678")
    end

    it "has user attribute" do
      expect(form.user).to eq("test_user")
    end

    it "has password attribute" do
      expect(form.password).to eq("test_password")
    end

    it "has encryption_key attribute" do
      expect(form.encryption_key).to eq("test_encryption_key")
    end
  end
end
