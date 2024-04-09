module ApplicationHelper
  def footer_contact
    @footer_contact ||= Rails.application.secrets[:footer_contact].to_h.with_indifferent_access[current_organization&.name]
  end
end
