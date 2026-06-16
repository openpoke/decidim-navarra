# frozen_string_literal: true

# Checks the authorization against the census for Getxo.
require "digest/md5"

# This class performs a check against the official census database in order
# to verify the citizen's residence.
class CensusAuthorizationHandler < Decidim::AuthorizationHandler
  include ActionView::Helpers::SanitizeHelper

  attribute :document_number, String
  attribute :date_of_birth, Date

  validates :date_of_birth, presence: true
  validates :document_number, format: { with: /(^[a-zA-Z]*)(\d+)([a-zA-Z]*$)/ }, presence: true

  validate :document_number_valid

  def date_of_birth
    return super if user.blank?

    Date.parse(user.extended_data["date_of_birth"]) if user.extended_data["date_of_birth"].present?
  end

  # If you need to store any of the defined attributes in the authorization you
  # can do it here.
  #
  # You must return a Hash that will be serialized to the authorization when
  # it's created, and available though authorization.metadata
  def metadata
    {
      date_of_birth: date_of_birth&.strftime("%Y-%m-%d"),
      street: extract_xpath_text("//calle"),
      street_number: extract_xpath_text("//portal").to_i
    }
  end

  def unique_id
    Digest::MD5.hexdigest(
      "#{document_number&.upcase}-#{Rails.application.secret_key_base}"
    )
  end

  def slim_response
    response.search("Body").children
  end

  private

  def extract_xpath_text(xpath)
    node = response&.xpath(xpath)
    node&.text&.strip
  end

  def sanitized_date_of_birth
    @sanitized_date_of_birth ||= date_of_birth&.strftime("%Y%m%d")
  end

  def extract_parts
    @extract_parts ||= /(^[a-zA-Z]*)(\d+)([a-zA-Z]*$)/.match document_number
  end

  def sanitized_document_number
    "#{extract_parts[1].upcase}#{extract_parts[2]}" if extract_parts
  end

  def sanitized_document_letter
    extract_parts[3].upcase if extract_parts
  end

  def document_number_valid
    return if response.blank?

    return if response.xpath("//existe").text == "SI"

    errors.add(:document_number, I18n.t("census_authorization_handler.invalid_document", scope: "decidim.authorization_handlers"))
  end

  def response
    return nil if document_number.blank? ||
                  date_of_birth.blank?

    begin
      service = GetxoWebservice.new("Validar")
      service.body = <<~XML
        <strDNI>#{sanitized_document_number}</strDNI>
        <strLetra>#{sanitized_document_letter}</strLetra>
        <strNacimiento>#{sanitized_date_of_birth}</strNacimiento>
      XML
      service.response
    rescue StandardError
      errors.add(:base, I18n.t("census_authorization_handler.connection_error", scope: "decidim.authorization_handlers"))
      nil
    end
  end
end
