# frozen_string_literal: true

class RelatedDocumentsContentBlockSync
  def self.activate(organization:, scope_name:, resource:)
    block = find_or_build(organization, scope_name, resource)
    return if block.published?

    block.weight = 50 if block.new_record?
    block.save! if block.new_record?
    block.publish!
  end

  def self.deactivate(organization:, scope_name:, resource:)
    block = find_or_build(organization, scope_name, resource)
    return if block.new_record? || !block.published?

    block.unpublish!
  end

  def self.find_or_build(organization, scope_name, resource)
    Decidim::ContentBlock.find_or_initialize_by(
      decidim_organization_id: organization.id,
      scope_name:,
      manifest_name: "related_documents",
      scoped_resource_id: resource.id
    )
  end
  private_class_method :find_or_build
end
