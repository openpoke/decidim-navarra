# frozen_string_literal: true

require "faraday"
require "faraday/multipart"
require "json"
require "base64"

class SendmailRestHandler
  class SendmailError < StandardError; end

  attr_reader :settings

  def initialize(settings)
    @settings = settings
    @connection = build_connection
  end

  def deliver!(mail)
    payload = build_payload(mail)

    response = @connection.post do |req|
      req.body = payload
    end
    handle_response!(response)
  end

  private

  # ---------- Connection ----------

  def build_connection
    url = settings.fetch(:url, ENV.fetch("SENDMAIL_REST_ADDRESS"))
    api_key = settings.fetch(:api_key, ENV.fetch("SENDMAIL_REST_API_KEY"))
    dry_run = settings[:dry_run]

    Faraday.new(url: build_url(url, dry_run)) do |f|
      f.request :multipart
      f.request :url_encoded
      f.adapter Faraday.default_adapter
    end.tap do |conn|
      auth = Base64.strict_encode64("api:#{api_key}")
      conn.headers["Authorization"] = "Basic #{auth}"
    end
  end

  def build_url(url, dry_run)
    return url if dry_run.nil?

    uri = URI(url)
    params = URI.decode_www_form(uri.query || "")
    params << ["dryRun", dry_run.to_s.downcase]
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end

  # ---------- Payload ----------

  def build_payload(mail)
    payload = {
      "to" => mail.to.join(", "),
      "subject" => mail.subject.to_s,
      "html" => extract_html_body(mail)
    }

    add_optional_headers(payload, mail)
    add_attachments(payload, mail)

    payload
  end

  def extract_html_body(mail)
    return mail.html_part&.body&.decoded if mail.multipart?

    mail.body.decoded
  end

  def add_optional_headers(payload, mail)
    payload["h:Reply-To"] = mail.reply_to.join(", ") if mail.reply_to.present?

    payload["h:Return-Receipt-To"] = mail.header["Return-Receipt-To"].value if mail.header["Return-Receipt-To"]

    payload["h:Disposition-Notification-To"] = mail.header["Disposition-Notification-To"].value if mail.header["Disposition-Notification-To"]
  end

  def add_attachments(payload, mail)
    return if mail.attachments.empty?

    payload["attachment"] = mail.attachments.map do |att|
      Faraday::Multipart::FilePart.new(
        StringIO.new(att.decoded),
        att.mime_type,
        att.filename
      )
    end
    # It seems that the web service expects a single attachment only
    payload["attachment"] = payload["attachment"].first
  end

  # ---------- Response handling ----------

  def handle_response!(response)
    raw = response.body.to_s

    unless response.success?
      raise SendmailError,
            "HTTP #{response.status} – #{raw.truncate(100)}"
    end

    data =
      JSON.parse(raw)
  rescue JSON::ParserError
    raise SendmailError,
          "Invalid JSON response – #{raw.truncate(100)}"
  else
    unless data["success"].to_s.casecmp("true").zero?
      raise SendmailError,
            "Send failed – success=#{data["success"]} message=#{data["message"]}"
    end
  end
end
