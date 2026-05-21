# frozen_string_literal: true

require "rails_helper"

describe "rake decidim_navarra:sync_related_documents_content_blocks", type: :task do
  let(:task) { Rake::Task["decidim_navarra:sync_related_documents_content_blocks"] }
  let(:organization) { create(:organization) }
  let(:process) { create(:participatory_process, organization:) }

  context "when space has document attachments" do
    before do
      allow($stdout).to receive(:puts).and_call_original
      Decidim::Attachment.skip_callback(:commit, :after, :activate_related_documents_block, raise: false)
      create(:attachment, :with_pdf, attached_to: process)
      Decidim::Attachment.set_callback(:commit, :after, :activate_related_documents_block)
    end

    it "activates the related_documents content block" do
      task.reenable
      task.invoke

      block = Decidim::ContentBlock.find_by(
        decidim_organization_id: organization.id,
        scope_name: "participatory_process_homepage",
        manifest_name: "related_documents",
        scoped_resource_id: process.id
      )
      expect(block).to be_published
      expect($stdout.string).to include("Activated related_documents block")
    end
  end

  context "when space has no document attachments" do
    before do
      allow($stdout).to receive(:puts).and_call_original
      create(:content_block,
             organization:,
             scope_name: :participatory_process_homepage,
             manifest_name: :related_documents,
             scoped_resource_id: process.id,
             published_at: Time.current)
    end

    it "deactivates the related_documents content block" do
      task.reenable
      task.invoke

      block = Decidim::ContentBlock.find_by(scoped_resource_id: process.id)
      expect(block).not_to be_published
      expect($stdout.string).to include("Deactivated related_documents block")
    end
  end
end
