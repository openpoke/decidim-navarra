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

    RelatedDocumentsContentBlockSync.activate(organization:, scope_name:, resource: attached_to)
  end

  def related_documents_scope_name
    scope = attached_to.manifest&.content_blocks_scope_name
    return if scope.blank?
    return unless Decidim.content_blocks.for(scope).any? { |manifest| manifest.name == :related_documents }

    scope
  end
end
