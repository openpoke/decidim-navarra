# frozen_string_literal: true

require "rails_helper"

RSpec.describe ParticipandoCensusWebservice do
  subject(:service) { described_class.new }

  let(:env_values) do
    {
      "PARTICIPANDO_URL" => "https://example.test",
      "PARTICIPANDO_ENTITY_NIF" => "B00000000",
      "PARTICIPANDO_APPLICATION" => "PMH-UDALA",
      "PARTICIPANDO_USER" => "demo",
      "PARTICIPANDO_PASSWORD" => "password",
      "PARTICIPANDO_ENCRYPTION_KEY" => "12345678901234567890123456789012",
      "PARTICIPANDO_ENCRYPTION_VECTOR" => "Hello,FromANIMSA"
    }
  end

  before do
    allow(ENV).to receive(:fetch) do |key|
      env_values.fetch(key)
    end
  end

  describe "#login" do
    it "returns the session id when login succeeds" do
      parsed_login = Nokogiri::XML("<WS_RESPUESTA><CONFIG><COD_ERROR>0</COD_ERROR></CONFIG><DATOS><IDSESION>ABC123</IDSESION></DATOS></WS_RESPUESTA>")
      allow(service).to receive(:call_soap).with("Login", anything).and_return(parsed_login)

      expect(service.login).to eq("ABC123")
    end

    it "raises when login returns an error" do
      parsed_login = Nokogiri::XML("<WS_RESPUESTA><CONFIG><COD_ERROR>2</COD_ERROR><DES_ERROR>Boom</DES_ERROR></CONFIG></WS_RESPUESTA>")
      allow(service).to receive(:call_soap).with("Login", anything).and_return(parsed_login)

      expect { service.login }.to raise_error(RuntimeError, "Login error 2: Boom")
    end
  end

  describe "#check_person" do
    it "calls login and solicitar_operacion and returns the parsed response" do
      parsed_operation = Nokogiri::XML("<WS_RESPUESTA><DATOS><ESTADO>E</ESTADO><CODRESULTADO>0</CODRESULTADO></DATOS></WS_RESPUESTA>")
      allow(service).to receive(:login).and_return("SESSION-ID")
      allow(service).to receive(:call_soap).with("SolicitarOperacion", anything).and_return(parsed_operation)

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
      soap_response = <<~XML
        <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
          <soap:Body>
            <LoginResponse xmlns="http://tempuri.org/">
              <LoginResult>&lt;WS_RESPUESTA&gt;&lt;CONFIG&gt;&lt;COD_ERROR&gt;0&lt;/COD_ERROR&gt;&lt;/CONFIG&gt;&lt;DATOS&gt;&lt;IDSESION&gt;SESSION-1&lt;/IDSESION&gt;&lt;/DATOS&gt;&lt;/WS_RESPUESTA&gt;</LoginResult>
            </LoginResponse>
          </soap:Body>
        </soap:Envelope>
      XML

      response_double = instance_double(Faraday::Response, body: soap_response)
      connection_double = instance_double(Faraday::Connection)
      allow(Faraday).to receive(:new).and_return(connection_double)
      allow(connection_double).to receive(:post).and_return(response_double)

      parsed = service.send(:call_soap, "Login", "<WS_PETICION/>")

      expect(parsed.xpath("//COD_ERROR").text).to eq("0")
      expect(parsed.xpath("//IDSESION").text).to eq("SESSION-1")
    end
  end
end
