# frozen_string_literal: true

# This class performs a check against the ANIMSA-PMH census webservice in order
# to verify the citizen is registered in the municipal census (padrón).
class CensusAuthorizationHandler < Decidim::AuthorizationHandler
  include ActionView::Helpers::SanitizeHelper

  DOCUMENT_TYPES = [:nif, :nie, :passport].freeze

  attribute :name, String
  attribute :first_surname, String
  attribute :document_type, Symbol
  attribute :document_number, String
  attribute :personal_data_access_consent, const_get(:Boolean), default: false

  validates :name, :first_surname, presence: true
  validates :document_type, inclusion: { in: DOCUMENT_TYPES }, presence: true
  validates :document_number, format: { with: /\A[A-Za-z0-9]*\z/ }, presence: true
  validates :personal_data_access_consent, presence: true, inclusion: [true]

  validate :census_service_verification, if: :personal_data_access_consent

  def document_types_for_select
    DOCUMENT_TYPES.map do |type|
      [I18n.t(type, scope: "decidim.census_authorization_handler.document_types"), type]
    end
  end

  private

  def citizen_found?
    return false unless response

    estado = response.xpath("//ESTADO").text
    cod_resultado = response.xpath("//CODRESULTADO").text

    estado == "E" && cod_resultado == "0"
  end

  def census_service_verification
    return if missing_attributes?

    return if citizen_found?

    errors.add(:base,
               I18n.t("decidim.census_authorization_handler.invalid_census_service_verification"))
  end

  def missing_attributes?
    [name, first_surname, document_type, document_number].any?(&:blank?)
  end

  def response
    return @response if defined?(@response)

    @response = begin
      service = ParticipandoCensusWebservice.new
      service.check_person(
        document_type: document_type,
        document_number: document_number,
        first_surname: first_surname,
        name: name
      )
    rescue StandardError => e
      Rails.logger.error "CENSUS WEBSERVICE ERROR: #{e.message}"
      errors.add(:base, I18n.t("decidim.census_authorization_handler.connection_error"))
      nil
    end
  end
end
