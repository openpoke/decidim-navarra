# frozen_string_literal: true

require "openssl"
require "base64"
require "digest"

# Handles communication with the ANIMSA-PMH census webservice.
# Implements LogIn + SolicitarOperacion as specified in
# "EXT - Acceso a Web Services de ANIMSA-PMH.doc"
#
# Required ENV vars (see .rbenv-vars):
#   PARTICIPANDO_URL              - webservice endpoint
#   PARTICIPANDO_ENTITY_NIF       - CIF of the entity (CIFENTIDAD)
#   PARTICIPANDO_APPLICATION      - application identifier (e.g. PMH-UDALA)
#   PARTICIPANDO_USER             - username provided by ANIMSA
#   PARTICIPANDO_PASSWORD         - base password provided by ANIMSA
#   PARTICIPANDO_ENCRYPTION_KEY   - 32-byte AES-256 key provided by ANIMSA
#   PARTICIPANDO_ENCRYPTION_VECTOR - 16-byte IV provided by ANIMSA
#
# NOTE: The SOAP namespace and parameter name below ("xmlEntrada") should be
# verified against the actual WSDL at PARTICIPANDO_URL?WSDL if the service
# rejects requests.
class ParticipandoCensusWebservice
  IDOPERACION = "NAVARRA_SEDE_PADRON_ComprobarPersona_WS"
  SOAP_NAMESPACE = "http://colaboradores.animsa.es/"

  # TIDEO values for document types
  DOCUMENT_TIDEO = {
    nif: 1,
    passport: 2,
    nie: 3
  }.freeze

  def initialize
    @url = ENV.fetch("PARTICIPANDO_URL")
    @entity_nif = ENV.fetch("PARTICIPANDO_ENTITY_NIF")
    @application = ENV.fetch("PARTICIPANDO_APPLICATION")
    @user = ENV.fetch("PARTICIPANDO_USER")
    @password = ENV.fetch("PARTICIPANDO_PASSWORD")
    @encryption_key = ENV.fetch("PARTICIPANDO_ENCRYPTION_KEY")
    @encryption_vector = ENV.fetch("PARTICIPANDO_ENCRYPTION_VECTOR")
  end

  # Calls LogIn and returns the IDSESION string (valid for 8 minutes).
  # Raises on webservice or authentication error.
  def login
    fechahora = current_fechahora
    contrasena = encrypt_password(fechahora)

    config_content = login_config_xml(fechahora, contrasena)
    control = generate_control_hash(config_content: config_content, fechahora: fechahora)

    peticion = build_peticion(config_content: config_content, control: control)
    parsed = call_soap("LogIn", peticion)

    cod_error = parsed.xpath("//COD_ERROR").text
    raise "LogIn error #{cod_error}: #{parsed.xpath("//DES_ERROR").text}" unless cod_error == "0"

    parsed.xpath("//IDSESION").text
  end

  # Calls LogIn then SolicitarOperacion with the given person data.
  # Returns the parsed Nokogiri document of the full response.
  def check_person(document_type:, document_number:, first_surname:, name:)
    session_id = login
    fechahora = current_fechahora
    tideo = DOCUMENT_TIDEO.fetch(document_type.to_sym)

    config_content = operation_config_xml(fechahora, session_id)
    datos_content = operation_datos_xml(document_number, tideo, first_surname, name)
    control = generate_control_hash(config_content: config_content, datos_content: datos_content, fechahora: fechahora)

    peticion = build_peticion(config_content: config_content, datos_content: datos_content, control: control)
    call_soap("SolicitarOperacion", peticion)
  end

  private

  def current_fechahora
    Time.now.strftime("%Y%m%d%H%M%S")
  end

  # Encrypts "#{password}#{fechahora}" using AES-256-CBC and returns Base64.
  def encrypt_password(fechahora)
    cipher = OpenSSL::Cipher.new("AES-256-CBC")
    cipher.encrypt
    cipher.key = @encryption_key.b.byteslice(0, 32)
    cipher.iv = @encryption_vector.b.byteslice(0, 16)
    encrypted = cipher.update("#{@password}#{fechahora}".encode("UTF-8")) + cipher.final
    Base64.strict_encode64(encrypted)
  end

  # Generates the CONTROL SHA256 hash as specified in section 5.3 of the doc.
  # Pass fechahora only for request hashes (omit for responses).
  def generate_control_hash(config_content:, datos_content: nil, fechahora: nil)
    config_children = count_xml_children(config_content)
    datos_children = datos_content ? count_xml_children(datos_content) : nil

    parts = [
      66.chr, # "B"
      52.chr, # "4"
      (datos_content || ""), # DATOS inner content (if exists)
      69.chr, # "E"
      config_content, # CONFIG inner content
      55.chr, # "7"
      (fechahora ? Time.now.strftime("%Y%m%d%H%M") : ""), # yyyymmddHHMM (requests only)
      95.chr, # "_"
      76.chr, # "L"
      76.chr, # "L"
      45.chr, # "-"
      (datos_children ? datos_children.to_s : ""), # DATOS child count (if exists)
      81.chr, # "Q"
      config_children.to_s, # CONFIG child count
      32.chr, # " "
      81.chr, # "Q"
      108.chr, # "l"
      50.chr, # "2"
      56.chr, # "8"
      54.chr # "6"
    ]

    Digest::SHA256.hexdigest(parts.join).upcase
  end

  def count_xml_children(xml_content)
    Nokogiri::XML("<root>#{xml_content}</root>").root.element_children.count
  end

  def login_config_xml(fechahora, contrasena)
    <<~XML.strip
      <FECHAHORA>#{fechahora}</FECHAHORA>
      <CIFENTIDAD>#{@entity_nif}</CIFENTIDAD>
      <APLICACION>#{@application}</APLICACION>
      <USERNAME>#{@user}</USERNAME>
      <CONTRASENA>#{contrasena}</CONTRASENA>
    XML
  end

  def operation_config_xml(fechahora, session_id)
    <<~XML.strip
      <FECHAHORA>#{fechahora}</FECHAHORA>
      <IDSESION>#{session_id}</IDSESION>
      <IDOPERACION>#{IDOPERACION}</IDOPERACION>
    XML
  end

  def operation_datos_xml(document_number, tideo, first_surname, name)
    <<~XML.strip
      <ENTRADA>
        <PERSONA>
          <DNI>#{document_number}</DNI>
          <TIDEN>#{tideo}</TIDEN>
          <APELLIDO1>#{first_surname}</APELLIDO1>
          <NOMBRE>#{name}</NOMBRE>
        </PERSONA>
      </ENTRADA>
    XML
  end

  def build_peticion(config_content:, control:, datos_content: nil)
    datos_node = datos_content ? "<DATOS>#{datos_content}</DATOS>" : ""
    <<~XML.strip
      <WS_PETICION>
        <CONFIG>#{config_content}</CONFIG>
        #{datos_node}
        <CONTROL>#{control}</CONTROL>
      </WS_PETICION>
    XML
  end

  def call_soap(action, peticion_xml)
    envelope = <<~SOAP
      <?xml version="1.0" encoding="UTF-8"?>
      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
          <#{action} xmlns="#{SOAP_NAMESPACE}">
            <xmlEntrada>#{peticion_xml}</xmlEntrada>
          </#{action}>
        </soap:Body>
      </soap:Envelope>
    SOAP

    begin
      response = Faraday.new(ssl: { verify: false }).post(@url) do |request|
        request.headers["Content-Type"] = "text/xml; charset=UTF-8"
        request.headers["SOAPAction"] = "#{SOAP_NAMESPACE}#{action}"
        request.headers["Host"] = URI.parse(@url).host
        request.body = envelope
      end
    rescue Faraday::Error => e
      Rails.logger.error "PARTICIPANDO WEBSERVICE CONNECTION ERROR: #{e.message}"
      raise
    end

    Nokogiri::XML(response.body).remove_namespaces!
  end
end
