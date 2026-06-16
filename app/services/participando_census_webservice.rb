# frozen_string_literal: true

class ParticipandoCensusWebservice
  def initialize(action)
    @action = action
    @body = ""
  end

  attr_accessor :action, :body

  def response
    return @response if defined?(@response)

    begin
      response ||= Faraday.new(ssl: { verify: false }).post ENV.fetch("CENSUS_URL", nil) do |request|
        request.headers["Content-Type"] = "text/xml;charset=UTF-8'"
        request.headers["SOAPAction"] = ["http://webtests02.getxo.org/#{action}"]
        request.body = request_body
      end
    rescue Faraday::Error => e
      Rails.logger.error "WEBSERVICE CONNECTION ERROR: #{e.message}"
      throw e
    end
    @response ||= Nokogiri::XML(response.body).remove_namespaces!
  end

  def slim_response
    response.search("Body").children
  end

  def request_body
    @request_body ||= <<~XML
      <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
          <#{action} xmlns="http://webtests02.getxo.org/">
            #{body}
          </#{action}>
        </soap:Body>
      </soap:Envelope>
    XML
  end
end
