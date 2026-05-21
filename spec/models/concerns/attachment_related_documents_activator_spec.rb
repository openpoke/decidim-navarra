# frozen_string_literal: true

require "rails_helper"

describe AttachmentRelatedDocumentsActivator do
  let(:organization) { create(:organization) }
  let(:process) { create(:participatory_process, organization:) }

  describe "after_create_commit" do
    context "when the attachment is a document on a participatory space" do
      it "activates the related_documents content block" do
        expect do
          create(:attachment, :with_pdf, attached_to: process)
        end.to change {
          Decidim::ContentBlock.where(
            decidim_organization_id: organization.id,
            scope_name: "participatory_process_homepage",
            manifest_name: "related_documents",
            scoped_resource_id: process.id
          ).count
        }.by(1)

        block = Decidim::ContentBlock.find_by(
          decidim_organization_id: organization.id,
          scope_name: "participatory_process_homepage",
          manifest_name: "related_documents",
          scoped_resource_id: process.id
        )
        expect(block).to be_published
      end
    end

    context "when the attachment is an image" do
      it "does not activate the content block" do
        expect do
          create(:attachment, :with_image, attached_to: process)
        end.not_to(change(Decidim::ContentBlock, :count))
      end
    end

    context "when attached_to is not a participatory space" do
      let(:component) { create(:component, participatory_space: process) }

      it "does not activate the content block" do
        expect do
          create(:attachment, :with_pdf, attached_to: component)
        end.not_to(change(Decidim::ContentBlock, :count))
      end
    end

    context "when the block already exists and is published" do
      before do
        create(:content_block,
               organization:,
               scope_name: :participatory_process_homepage,
               manifest_name: :related_documents,
               scoped_resource_id: process.id,
               published_at: Time.current)
      end

      it "does not create a duplicate" do
        expect do
          create(:attachment, :with_pdf, attached_to: process)
        end.not_to(change(Decidim::ContentBlock, :count))
      end
    end
  end
end
