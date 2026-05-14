# frozen_string_literal: true

Rails.application.config.to_prepare do
  Decidim::Attachment.include AttachmentRelatedDocumentsActivator
  Decidim::Attachment.scope :documents, -> { where.not("content_type LIKE ?", "image/%") }
end
