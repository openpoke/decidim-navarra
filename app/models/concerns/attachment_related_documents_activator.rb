# frozen_string_literal: true

module AttachmentRelatedDocumentsActivator
  extend ActiveSupport::Concern

  included do
    after_create_commit :activate_related_documents_block
  end

  private

  def activate_related_documents_block
    return unless document?
    return unless attached_to.is_a?(Decidim::Participable)

    scope_name = related_documents_scope_name
    return if scope_name.blank?
    return if organization.blank?

    publish_related_documents_block(scope_name)
  end

  def related_documents_scope_name
    scope = attached_to.manifest&.content_blocks_scope_name
    return if scope.blank?
    return unless Decidim.content_blocks.for(scope).any? { |manifest| manifest.name == :related_documents }

    scope
  end

  def publish_related_documents_block(scope_name)
    content_block = Decidim::ContentBlock.find_or_initialize_by(
      decidim_organization_id: organization.id,
      scope_name:,
      manifest_name: "related_documents",
      scoped_resource_id: attached_to.id
    )
    content_block.weight = 50 if content_block.new_record?
    content_block.publish! unless content_block.published?
  end
end
