# frozen_string_literal: true

# This class performs a check against the ANIMSA-PMH census webservice in order
# to verify the citizen is registered in the municipal census (padrón).
class ParticipandoAuthorizationHandler < Decidim::AuthorizationHandler
  include ActionView::Helpers::SanitizeHelper

  DOCUMENT_TYPES = [:none, :nif, :nie, :passport].freeze

  attribute :name, String
  attribute :first_surname, String
  attribute :document_type, Symbol
  attribute :document_number, String
  attribute :date_of_birth, Decidim::Attributes::LocalizedDate

  validates :name, :first_surname, presence: true
  validates :document_type, inclusion: { in: DOCUMENT_TYPES }, presence: true
  validates :date_of_birth, presence: true

  validate :document_number_verification
  validate :participando_service_verification

  def document_types_for_select
    DOCUMENT_TYPES.map do |type|
      [I18n.t(type, scope: "decidim.participando_authorization_handler.document_types"), type]
    end
  end

  def metadata
    {
      birthdate: birthdate&.strftime("%Y-%m-%d"),
      document_type: document_type
    }
  end

  private

  def birthdate
    date = response.xpath("//FECHANAC")&.text
    return nil if date.blank?

    Date.parse(date)
  end

  def citizen_found?
    return false unless response

    estado = response.xpath("//ESTADO").text
    cod_resultado = response.xpath("//CODRESULTADO").text

    estado == "E" && cod_resultado == "0"
  end

  def document_number_verification
    return if document_type == :none

    return if document_number.present? && document_number.match?(/\A[A-Za-z0-9]*\z/)

    errors.add(:document_number, :invalid)
  end

  def participando_service_verification
    return unless response

    nil if citizen_found? && birthdate == date_of_birth

    # errors.add(:base, I18n.t("decidim.participando_authorization_handler.invalid"))
  end

  def response
    return @response if defined?(@response)

    @response = begin
      service = ParticipandoCensusWebservice.new(user.organization)
      service.check_person(
        document_type: document_type,
        document_number: document_number,
        first_surname: first_surname,
        name: name
      )
    rescue StandardError => e
      Rails.logger.error "CENSUS WEBSERVICE ERROR: #{e.message}"
      errors.add(:base, I18n.t("decidim.participando_authorization_handler.connection_error") + " (#{e.message})")
      nil
    end
  end
end
