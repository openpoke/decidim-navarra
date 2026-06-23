# frozen_string_literal: true

require "rails_helper"
require "cgi"

RSpec.describe ParticipandoCensusWebservice do
  subject(:service) { described_class.new(organization) }

  let(:organization) { create(:organization, :with_participando_setting) }
  let(:env_values) do
    {
      "PARTICIPANDO_URL" => "https://example.test",
      "PARTICIPANDO_APPLICATION" => "PMH-UDALA",
      "PARTICIPANDO_ENCRYPTION_KEY" => "12345678901234567890123456789012",
      "PARTICIPANDO_ENCRYPTION_VECTOR" => "Hello,FromANIMSA"
    }
  end

  before do
    original_fetch = ENV.method(:fetch)
    allow(ENV).to receive(:fetch) do |key, *args|
      if env_values.has_key?(key)
        env_values.fetch(key)
      elsif args.empty?
        original_fetch.call(key)
      else
        args.first
      end
    end
  end

  describe "#login" do
    it "returns the session id when login succeeds" do
      login_payload = <<~XML
        <WS_RESPUESTA>
          <CONFIG><COD_ERROR>0</COD_ERROR></CONFIG>
          <DATOS><IDSESION>ABC123</IDSESION></DATOS>
        </WS_RESPUESTA>
      XML

      stub_soap_responses(soap_response("Login", login_payload))

      expect(service.login).to eq("ABC123")
    end

    it "raises when login returns an error" do
      login_payload = <<~XML
        <WS_RESPUESTA>
          <CONFIG>
            <COD_ERROR>2</COD_ERROR>
            <DES_ERROR>Boom</DES_ERROR>
          </CONFIG>
        </WS_RESPUESTA>
      XML

      stub_soap_responses(soap_response("Login", login_payload))

      expect { service.login }.to raise_error(RuntimeError, "Login error 2: Boom")
    end
  end

  describe "#check_person" do
    it "calls login and solicitar_operacion and returns the parsed response" do
      login_payload = <<~XML
        <WS_RESPUESTA>
          <CONFIG><COD_ERROR>0</COD_ERROR></CONFIG>
          <DATOS><IDSESION>SESSION-ID</IDSESION></DATOS>
        </WS_RESPUESTA>
      XML
      operation_payload = <<~XML
        <WS_RESPUESTA>
          <DATOS>
            <ESTADO>E</ESTADO>
            <CODRESULTADO>0</CODRESULTADO>
          </DATOS>
        </WS_RESPUESTA>
      XML

      stub_soap_responses(
        soap_response("Login", login_payload),
        soap_response("SolicitarOperacion", operation_payload)
      )

      result = service.check_person(
        document_type: :nif,
        document_number: "12345678A",
        first_surname: "Lopez",
        name: "Ana"
      )

      expect(result.xpath("//ESTADO").text).to eq("E")
      expect(result.xpath("//CODRESULTADO").text).to eq("0")
    end
  end

  describe "#call_soap" do
    it "parses nested xml payload from LoginResult" do
      login_payload = <<~XML
        <WS_RESPUESTA>
          <CONFIG><COD_ERROR>0</COD_ERROR></CONFIG>
          <DATOS><IDSESION>SESSION-1</IDSESION></DATOS>
        </WS_RESPUESTA>
      XML
      stub_soap_responses(soap_response("Login", login_payload))

      parsed = service.send(:call_soap, "Login", "<WS_PETICION/>")

      expect(parsed.xpath("//COD_ERROR").text).to eq("0")
      expect(parsed.xpath("//IDSESION").text).to eq("SESSION-1")
    end
  end

  def soap_response(action, payload)
    escaped_payload = CGI.escapeHTML(payload.gsub(/>\s+</, "><").strip)
    <<~XML
      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
          <#{action}Response xmlns="http://tempuri.org/">
            <#{action}Result>#{escaped_payload}</#{action}Result>
          </#{action}Response>
        </soap:Body>
      </soap:Envelope>
    XML
  end

  def stub_soap_responses(*response_bodies)
    response_doubles = response_bodies.map { |body| instance_double(Faraday::Response, body: body) }
    connection_double = instance_double(Faraday::Connection)

    allow(Faraday).to receive(:new).and_return(connection_double)
    allow(connection_double).to receive(:post).and_return(*response_doubles)
  end
end
