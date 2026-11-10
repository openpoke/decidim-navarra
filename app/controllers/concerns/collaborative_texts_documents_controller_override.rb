# frozen_string_literal: true

module CollaborativeTextsDocumentsControllerOverride
  extend ActiveSupport::Concern

  included do
    alias_method :navarra_original_documents, :documents

    private

    def documents
      navarra_original_documents.order(
        Arel.sql("COALESCE((substring(title from '^\\d+'))::integer, 999999), title")
      )
    end
  end
end
