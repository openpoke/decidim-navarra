# frozen_string_literal: true

module ApplicationHelper
  def footer_contact
    @footer_contact ||= JSON.parse(Rails.application.secrets[:footer_contact].presence || "{}").with_indifferent_access[current_organization&.name]
  end
end
