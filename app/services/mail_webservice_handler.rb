# frozen_string_literal: true

class MailWebserviceHandler
  def initialize(options = {}); end

  def settings
    @settings ||= {}
  end

  def send_email(options = {}); end

  def send_raw_email(mail, _args = {})
    response = Faraday.post webservice_address do |request|
      request.headers["Content-Type"] = "text/xml"
      request.body = raw_xml(mail)
    end

    Nokogiri::XML(response.body).remove_namespaces!
  end
  alias deliver! send_raw_email
  alias deliver send_raw_email

  private

  def raw_xml(mail)
    <<-XML
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:env="http://www.navarra.es/EnvioCorreos" xmlns:arr="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
          <soapenv:Header>
              <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
                  <wsse:UsernameToken wsu:Id="UsernameToken-1">
                      <wsse:Username>#{request_configuration.username_token_user}</wsse:Username>
                      <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">#{request_configuration.username_token_password}</wsse:Password>
                  </wsse:UsernameToken>
              </wsse:Security>
          </soapenv:Header>
          <soapenv:Body>
              <env:EnviaCorreo>
                  <!--Optional:-->
                  <env:asunto>#{mail.subject}</env:asunto>
                  <!--Optional:-->
                  <env:cuerpo>#{mail.body}</env:cuerpo>
                  <!--Optional:-->
                  <env:origen>participacionciudadana@navarra.es</env:origen>
                  <!--Optional:-->
                  <env:destinos>
                      <!--Zero or more repetitions:-->
    #{mail.to.map { |addressee| "<arr:string>#{addressee}</arr:string>" }.join("\n")}
                      <arr:string>eduardo@populate.tools</arr:string>
                  </env:destinos>
                  <!--Optional:-->
                  <env:servidor>correo.admon-cfnavarra.es</env:servidor>
                  <!--Optional:-->
                  <env:usuario>SVC_participacion</env:usuario>
                  <!--Optional:-->
                  <env:clave>Participacion2020</env:clave>
                  <!--Optional:-->
                  <!--env:respuesta>?</env:respuesta -->
                  <!--Optional:-->
                  <env:codaplicacion>172</env:codaplicacion>
              </env:EnviaCorreo>
          </soapenv:Body>
      </soapenv:Envelope>
    XML
  end

  def webservice_address
    @webservice_address ||= Rails.application.secrets.email_webservice_address
  end

  def request_configuration
    @request_configuration ||= OpenStruct.new(Rails.application.secrets.email_webservice_configuration)
  end
end
