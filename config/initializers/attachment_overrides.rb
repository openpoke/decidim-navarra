# frozen_string_literal: true

Rails.application.config.to_prepare { Decidim::Attachment.include AttachmentRelatedDocumentsActivator }
