# frozen_string_literal: true

class MailWebserviceHandler < Decidim::ApplicationMailer
  def initialize(options = {}); end

  def settings
    @settings ||= {}
  end

  def send_raw_email(mail, _args = {})
    request_body = raw_xml(mail, subject: extract_subject(mail), body: extract_body(mail))

    response = Faraday.post webservice_address do |request|
      request.headers["Content-Type"] = "application/soap+xml; charset=utf-8; action=\"http://www.navarra.es/EnvioCorreos/IEnvioCorreos/EnviaCorreoDetallado\""
      request.body = request_body
    end

    response_body = Nokogiri::XML(response.body).remove_namespaces!

    Rails.logger.info "[EMAIL_WEBSERVICE] Request: #{request_body}"
    Rails.logger.info "[EMAIL_WEBSERVICE] Response: #{response_body}"

    response_body
  end
  alias deliver! send_raw_email
  alias deliver send_raw_email

  private

  def extract_subject(mail)
    mail.subject.encode(xml: :text)
  end

  def extract_body(mail)
    mail = mail.parts.find { |message| /text\/html/.match?(message.content_type) } || mail.parts.first if mail.multipart?
    mail.body.to_s.encode(xml: :text)
  end

  def timestamp_format
    "%Y-%m-%dT%H:%M:%S.%LZ"
  end

  def timestamp
    @timestamp ||= OpenStruct.new(
      created: DateTime.current.strftime(timestamp_format),
      expires: 3.minutes.from_now.strftime(timestamp_format)
    )
  end

  def raw_xml(mail, opts = {})
    <<-XML
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:u="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
    <s:Header>
        <o:Security s:mustUnderstand="1" xmlns:o="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
            <u:Timestamp u:Id="_0">
                <u:Created>#{timestamp.created}</u:Created>
                <u:Expires>#{timestamp.expires}</u:Expires>
            </u:Timestamp>
            <o:UsernameToken u:Id="uuid-d368d733-2147-46e2-903f-7dda72bf934a-3">
                <o:Username>#{request_configuration.username_token_user}</o:Username>
                <o:Password>#{request_configuration.username_token_password}</o:Password>
            </o:UsernameToken>
        </o:Security>
    </s:Header>
    <s:Body>
        <EnviaCorreoDetallado xmlns="http://www.navarra.es/EnvioCorreos">
            <mensaje xmlns:a="http://schemas.datacontract.org/2004/07/cpEnvioCorreos.Entidades" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
                <_key xmlns="http://schemas.datacontract.org/2004/07/Indra.Componentes">00000000-0000-0000-0000-000000000000</_key>
                <a:Adjuntos i:nil="true"/>
                <a:Asunto>#{opts[:subject]}</a:Asunto>
                <a:Cc i:nil="true" xmlns:b="http://schemas.microsoft.com/2003/10/Serialization/Arrays"/>
                <a:Cco i:nil="true" xmlns:b="http://schemas.microsoft.com/2003/10/Serialization/Arrays"/>
                <a:Cuerpo>#{opts[:body]}</a:Cuerpo>
                <a:Destinatarios xmlns:b="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
                    #{mail.to.map { |addressee| "<b:string>#{addressee}</b:string>" }.join("\n")}
                </a:Destinatarios>
                <a:Origen>participanavarra@navarra.es</a:Origen>
                <a:Tipo>HTML</a:Tipo>
            </mensaje>
            <servidor>correo.admon-cfnavarra.es</servidor>
            <usuario>SVC_participacion</usuario>
            <clave>Participacion2020</clave>
            <respuesta/>
            <codaplicacion>172</codaplicacion>
        </EnviaCorreoDetallado>
    </s:Body>
</s:Envelope>
    XML
  end

  def webservice_address
    @webservice_address ||= Rails.application.secrets.email_webservice_address
  end

  def request_configuration
    @request_configuration ||= OpenStruct.new(Rails.application.secrets.email_webservice_configuration)
  end
end
