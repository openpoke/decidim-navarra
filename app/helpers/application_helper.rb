# frozen_string_literal: true

module ApplicationHelper
  def footer_contact
    @footer_contact ||= JSON.parse(ENV["FOOTER_CONTACT"].presence || "{}").with_indifferent_access[current_organization&.name]
  end
end
