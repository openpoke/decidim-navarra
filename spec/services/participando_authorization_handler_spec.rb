# frozen_string_literal: true

require "rails_helper"

RSpec.describe ParticipandoAuthorizationHandler do
  subject(:handler) do
    described_class.new(
      name: "Ana",
      first_surname: "Lopez",
      document_type: document_type,
      document_number: document_number,
      date_of_birth: date_of_birth,
      user: user
    )
  end

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization:) }
  let(:document_type) { :nif }
  let(:service_double) { instance_double(ParticipandoCensusWebservice) }
  let(:document_number) { "12345678A" }
  let(:date_of_birth) { Date.parse("1990-02-10") }

  before do
    allow(ParticipandoCensusWebservice).to receive(:new).and_return(service_double)
    allow(service_double).to receive(:check_person).and_return(response_xml)
    allow(I18n).to receive(:t).and_call_original
    allow(I18n).to receive(:t).with(/\Adecidim\.participando_authorization_handler\./).and_return("translation")
  end

  describe "validations" do
    context "when census response is valid and birthdate matches" do
      let(:response_xml) do
        Nokogiri::XML("<WS_RESPUESTA><DATOS><ESTADO>E</ESTADO><CODRESULTADO>0</CODRESULTADO><FECHANAC>1990-02-10</FECHANAC></DATOS></WS_RESPUESTA>")
      end

      it "is valid" do
        expect(handler).to be_valid
      end

      it "returns metadata with birthdate and document type" do
        expect(handler.metadata).to eq(
          birthdate: "1990-02-10",
          document_type: :nif
        )
      end
    end

    context "when census response birthdate does not match" do
      let(:response_xml) do
        Nokogiri::XML("<WS_RESPUESTA><DATOS><ESTADO>E</ESTADO><CODRESULTADO>0</CODRESULTADO><FECHANAC>1991-01-01</FECHANAC></DATOS></WS_RESPUESTA>")
      end

      it "adds a base error" do
        handler.valid?

        expect(handler.errors[:base]).not_to be_empty
      end
    end

    context "when document type is not none and document number is invalid" do
      let(:response_xml) do
        Nokogiri::XML("<WS_RESPUESTA><DATOS><ESTADO>E</ESTADO><CODRESULTADO>0</CODRESULTADO><FECHANAC>1990-02-10</FECHANAC></DATOS></WS_RESPUESTA>")
      end
      let(:document_number) { "12-34" }

      it "adds document number error" do
        handler.valid?

        expect(handler.errors[:document_number]).not_to be_empty
      end
    end

    context "when document type is none" do
      let(:document_type) { :none }
      let(:document_number) { nil }
      let(:response_xml) do
        Nokogiri::XML("<WS_RESPUESTA><DATOS><ESTADO>E</ESTADO><CODRESULTADO>0</CODRESULTADO><FECHANAC>1990-02-10</FECHANAC></DATOS></WS_RESPUESTA>")
      end

      it "does not require document number format" do
        handler.valid?

        expect(handler.errors[:document_number]).to be_empty
      end
    end

    context "when service raises an exception" do
      let(:response_xml) { nil }

      before do
        allow(service_double).to receive(:check_person).and_raise(StandardError, "timeout")
      end

      it "adds connection error to base" do
        handler.valid?

        expect(handler.errors[:base]).not_to be_empty
      end
    end
  end
end
