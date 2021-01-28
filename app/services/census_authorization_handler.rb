# frozen_string_literal: true

# This class performs a check against the official census database in order
# to verify the citizen's residence.
class CensusAuthorizationHandler < Decidim::AuthorizationHandler
  include ActionView::Helpers::SanitizeHelper
  include Virtus::Multiparams

  PROVINCE_CODES = JSON.parse(File.read(File.join(File.dirname(__FILE__), "province_codes.json")))
  DOCUMENT_TYPE_SERVICE_VALUES = {
    nif: { name: "NIF", spanish_nationality: "s" },
    nie: { name: "NIE", spanish_nationality: "n" },
    passport: { name: "Pasaporte", spanish_nationality: "n" }
  }.freeze

  attribute :name, String
  attribute :first_surname, String
  attribute :second_surname, String
  attribute :document_type, Symbol
  attribute :document_number, String
  attribute :date_of_birth, Date
  attribute :province_id, String
  attribute :personal_data_access_consent, Boolean

  validates :name, :first_surname, :second_surname, :date_of_birth, :province_id, presence: true
  validates :document_type, inclusion: { in: DOCUMENT_TYPE_SERVICE_VALUES.keys }, presence: true
  validates :document_number, format: { with: /\A[A-z0-9]*\z/ }, presence: true
  validates :personal_data_access_consent, presence: true, inclusion: [true]

  validate :census_service_verification, if: :personal_data_access_consent

  # If you need to store any of the defined attributes in the authorization you
  # can do it here.
  #
  # You must return a Hash that will be serialized to the authorization when
  # it's created, and available though authorization.metadata
  def metadata
    super.merge(
      date_of_birth: date_of_birth&.strftime("%Y-%m-%d")
    )
  end

  def document_types_for_select
    DOCUMENT_TYPE_SERVICE_VALUES.keys.map do |type|
      [I18n.t(type, scope: "decidim.census_authorization_handler.document_types"), type]
    end
  end

  def provinces_for_select
    PROVINCE_CODES.map do |code, name|
      [name, code]
    end
  end

  private

  def citizen_found?
    status == "0003"
  end

  def status
    @status ||= response.xpath("//codigoEstado").text
  end

  def spanish_nationality_service_value
    @spanish_nationality_service_value ||= DOCUMENT_TYPE_SERVICE_VALUES.dig(document_type, :spanish_nationality)
  end

  def document_type_service_value
    @document_type_service_value ||= DOCUMENT_TYPE_SERVICE_VALUES.dig(document_type, :name)
  end

  def date_of_birth_service_value
    @date_of_birth_service_value ||= date_of_birth.strftime("%Y%m%d")
  end

  def census_service_verification
    return if missing_attributes?

    errors.add(:base, I18n.t("decidim.census_authorization_handler.invalid_census_service_verification")) unless citizen_found?
  end

  def missing_attributes?
    [name,
     first_surname,
     second_surname,
     date_of_birth,
     province_id,
     document_type,
     document_number].any?(&:blank?)
  end

  def request_configuration
    @request_configuration ||= OpenStruct.new(Rails.application.secrets.census_webservice_configuration)
  end

  def request_body
    @request_body ||= <<-XML
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ser="http://services.INE.SVCD.componentes.navarra.es/">
        <soapenv:Header/>
        <soapenv:Body>
            <ser:VerificacionDatosResidenciaAmbito>
                <arg0>
                    <solicitante>
                        <codigoAplicacion>#{request_configuration.code}</codigoAplicacion>
                        <consentimiento>Si</consentimiento>
                        <finalidad>#{request_configuration.purpose}</finalidad>
                        <funcionario>
                            <nifFuncionario>#{request_configuration.official_document_number}</nifFuncionario>
                            <nombreCompletoFuncionario>#{request_configuration.official_name}</nombreCompletoFuncionario>
                        </funcionario>
                        <idExpediente>#{request_configuration.request_id}</idExpediente>
                        <procedimiento>
                            <codProcedimiento>#{request_configuration.procedure_code}</codProcedimiento>
                            <nombreProcedimiento>#{request_configuration.procedure_name}</nombreProcedimiento>
                        </procedimiento>
                        <unidadTramitadora>#{request_configuration.processing_unit}</unidadTramitadora>
                    </solicitante>
                    <titularResidencia>
                        <apellido1>#{first_surname}</apellido1>
                        <apellido2>#{second_surname}</apellido2>
                        <documentacion>#{document_number}</documentacion>
                        <espanol>#{spanish_nationality_service_value}</espanol>
                        <!--Optional:-->
                        <infoNacimiento>
                            <fecha>#{date_of_birth_service_value}</fecha>
                            <municipio></municipio>
                            <provincia></provincia>
                        </infoNacimiento>
                        <nombre>#{name}</nombre>
                        <!--Optional:-->
                        <nombreCompleto></nombreCompleto>
                        <residencia>
                            <!--Optional:-->
                            <municipio></municipio>
                            <provincia>#{province_id}</provincia>
                        </residencia>
                        <tipoDocumentacion>#{document_type_service_value}</tipoDocumentacion>
                    </titularResidencia>
                </arg0>
            </ser:VerificacionDatosResidenciaAmbito>
        </soapenv:Body>
      </soapenv:Envelope>
    XML
  end

  def response
    return @response if defined?(@response)

    response ||= Faraday.post Rails.application.secrets.census_webservice_address do |request|
      request.headers["Content-Type"] = "text/xml"
      request.body = request_body
    end

    @response ||= Nokogiri::XML(response.body).remove_namespaces!
  end
end
