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
# NOTE: The SOAP namespace and parameter name below ("strXmlLogin") should be
# verified against the actual WSDL at PARTICIPANDO_URL?WSDL if the service
# rejects requests.
class ParticipandoCensusWebservice
  IDOPERACION = "NAVARRA_SEDE_PADRON_ComprobarPersona_WS"
  SOAP_NAMESPACE = "http://tempuri.org/"

  # TIDEO values for document types
  DOCUMENT_TIDEO = {
    none: 0,
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
    control_data = control_hash_data(config_content: config_content, fechahora: fechahora)

    parsed = call_soap("Login", build_peticion(config_content: config_content, control: control_data[:lower]))
    cod_error = parsed.xpath("//COD_ERROR").text
    raise "Login error #{cod_error}: #{parsed.xpath("//DES_ERROR").text}" unless cod_error == "0"

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
    control = control_hash_data(config_content: config_content, datos_content: datos_content, fechahora: fechahora)[:lower]

    peticion = build_peticion(config_content: config_content, datos_content: datos_content, control: control)
    call_soap("SolicitarOperacion", peticion)
  rescue StandardError => e
    Rails.logger.error "PARTICIPANDO WEBSERVICE ERROR: #{e.message}"
    raise e
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
  def control_hash_data(config_content:, fechahora:, datos_content: nil)
    normalized_config_content = normalize_xml_content(config_content)
    normalized_datos_content = datos_content ? normalize_xml_content(datos_content) : nil

    config_children = count_xml_children(normalized_config_content)
    datos_children = normalized_datos_content ? count_xml_children(normalized_datos_content) : nil

    parts = [
      66.chr, # "B"
      52.chr, # "4"
      (normalized_datos_content ? "<DATOS>#{normalized_datos_content}</DATOS>" : ""), # DATOS content (if exists)
      69.chr, # "E"
      "<CONFIG>#{normalized_config_content}</CONFIG>", # CONFIG content
      55.chr, # "7"
      fechahora.slice(0, 12), # FECHAHORA (if exists)
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

    control_input = parts.join
    digest = Digest::SHA256.hexdigest(control_input)

    {
      lower: digest,
      upper: digest.upcase,
      input: control_input,
      config_children: config_children,
      datos_children: datos_children
    }
  end

  def log_control_debug(action:, control_data:)
    return unless ENV["PARTICIPANDO_DEBUG_CONTROL"] == "1"

    Rails.logger.warn(
      "PARTICIPANDO CONTROL DEBUG [#{action}] upper=#{control_data[:upper]} lower=#{control_data[:lower]} " \
      "config_children=#{control_data[:config_children]} datos_children=#{control_data[:datos_children].to_s.empty? ? "-" : control_data[:datos_children]} " \
      "input=#{control_data[:input]}"
    )
  end

  def count_xml_children(xml_content)
    Nokogiri::XML("<root>#{xml_content}</root>").root.element_children.count
  end

  def login_config_xml(fechahora, contrasena)
    normalize_xml_content(<<~XML)
      <FECHAHORA>#{fechahora}</FECHAHORA>
      <CIFENTIDAD>#{@entity_nif}</CIFENTIDAD>
      <APLICACION>#{@application}</APLICACION>
      <USERNAME>#{@user}</USERNAME>
      <CONTRASENA>#{contrasena}</CONTRASENA>
    XML
  end

  def operation_config_xml(fechahora, session_id)
    normalize_xml_content(<<~XML)
      <FECHAHORA>#{fechahora}</FECHAHORA>
      <IDSESION>#{session_id}</IDSESION>
      <IDOPERACION>#{IDOPERACION}</IDOPERACION>
    XML
  end

  def operation_datos_xml(document_number, tideo, first_surname, name)
    normalize_xml_content(<<~XML)
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
    normalize_xml_content(<<~XML)
      <WS_PETICION>
        <CONFIG>#{config_content}</CONFIG>
        #{datos_node}
        <CONTROL>#{control}</CONTROL>
      </WS_PETICION>
    XML
  end

  def call_soap(action, peticion_xml)
    parameter_name = soap_parameter_name(action)
    envelope = <<~SOAP
      <?xml version="1.0" encoding="UTF-8"?>
      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
          <#{action} xmlns="#{SOAP_NAMESPACE}">
            <#{parameter_name}><![CDATA[#{peticion_xml}]]></#{parameter_name}>
          </#{action}>
        </soap:Body>
      </soap:Envelope>
    SOAP
    envelope.gsub!(/>\s+</, "><") # Remove whitespace between tags
    begin
      conn = Faraday.new(
        url: @url,
        ssl: { verify: false },
        headers: {
          "Content-Type" => "text/xml; charset=UTF-8",
          "SOAPAction" => "http://tempuri.org/#{action}",
          "Host" => "colabora.animsa.es"
        }
      )

      response = conn.post("/serviciocolaboradores/servicios.asmx") do |req|
        req.body = envelope
      end
    rescue Faraday::Error => e
      Rails.logger.error "PARTICIPANDO WEBSERVICE CONNECTION ERROR: #{e.message}"
      raise e
    end

    parsed_response = Nokogiri::XML(response.body).remove_namespaces!
    result_node = parsed_response.at_xpath("//#{action}Response/#{action}Result")
    return parsed_response unless result_node

    result_payload = result_node.text.to_s.strip
    return parsed_response if result_payload.empty?

    Nokogiri::XML(result_payload).remove_namespaces!
  end

  def soap_parameter_name(action)
    case action
    when "Login"
      "strXmlLogin"
    when "SolicitarOperacion"
      "strXmlSolicitudOperacion"
    else
      "xmlEntrada"
    end
  end

  def normalize_xml_content(xml)
    xml.to_s.strip.gsub(/>\s+</, "><")
  end
end
