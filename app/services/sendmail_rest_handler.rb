# frozen_string_literal: true

require "base64"
require "json"
require "uri"
require "ostruct"
require "stringio"

class SendmailRestHandler
  def initialize(values = {})
    @settings = values.dup
  end

  def send_raw_email(mail, args = {})
    payload = build_payload(mail, args)

    response = Faraday.post(rest_address) do |request|
      request.headers["Authorization"] = basic_auth_header
      request.headers["Accept"] = "application/json"
      request.body = payload
    end

    body = parse_json(response.body)

    Rails.logger.info "[EMAIL_REST] POST #{rest_address}"
    Rails.logger.info "[EMAIL_REST] Request keys: #{payload.keys.sort.join(", ")}"
    Rails.logger.info "[EMAIL_REST] Response status: #{response.status} body: #{body}"

    body
  end
  alias deliver! send_raw_email
  alias deliver send_raw_email

  private

  def build_payload(mail, args)
    to = Array(mail.to).compact
    cc = Array(mail.cc).compact
    bcc = Array(mail.bcc).compact

    html_body, text_body = extract_bodies(mail)

    payload = {}
    payload["To"] = to.join(",") if to.any?
    payload["cc"] = cc.join(",") if cc.any?
    payload["bcc"] = bcc.join(",") if bcc.any?
    payload["subject"] = extract_subject(mail)
    payload["html"] = html_body if html_body
    payload["text"] = text_body if text_body

    reply_to = Array(mail.reply_to).compact
    payload["h:Reply-To"] = reply_to.join(",") if reply_to.any?

    return_receipt = header_value(mail, "Return-Receipt-To")
    payload["h:Return-Receipt-To"] = return_receipt if return_receipt

    disposition_notification = header_value(mail, "Disposition-Notification-To")
    payload["h:Disposition-Notification-To"] = disposition_notification if disposition_notification

    # Optional dry run flag, from args or ENV
    dryrun = args[:dryrun]
    dryrun = env_true?(ENV.fetch("EMAIL_REST_DRYRUN", nil)) if dryrun.nil?
    payload["o:dryrun"] = "true" if dryrun

    # Attachments as repeated 'attachment' parts
    if mail.attachments.any?
      payload["attachment"] = mail.attachments.map do |attachment|
        Faraday::UploadIO.new(StringIO.new(attachment.decoded), attachment.mime_type, attachment.filename)
      end
    end

    payload
  end

  def extract_subject(mail)
    mail.subject&.truncate(170)&.encode(xml: :text)
  end

  def extract_bodies(mail)
    if mail.multipart?
      html_part = mail.parts.find { |p| p.content_type&.include?("text/html") }
      text_part = mail.parts.find { |p| p.content_type&.include?("text/plain") }
      html = html_part&.body&.to_s
      text = text_part&.body&.to_s
      # Fallback if only one available
      html ||= text if html.nil? && text
      [html, text]
    elsif mail.content_type&.include?("text/html")
      [mail.body.to_s, nil]
    else
      [nil, mail.body.to_s]
    end
  end

  def header_value(mail, name)
    value = mail.header[name]&.value
    value.is_a?(Array) ? value.join(",") : value
  end

  def parse_json(str)
    JSON.parse(str)
  rescue JSON::ParserError
    { "raw" => str }
  end

  def env_true?(val)
    %w(1 true TRUE yes YES on ON).include?(val.to_s)
  end

  def rest_address
    env = ENV.fetch("EMAIL_REST_ADDRESS", nil)
    return env if env.present?

    base = Rails.application.secrets.email_webservice_address
    return base if base&.match?(%r{/Sendmail|/SendMail})

    return nil unless base

    uri = URI(base)
    dir = File.dirname(uri.path)
    uri.path = File.join(dir, "SendMail")
    uri.to_s
  end

  def basic_auth_header
    # API key format: can be just token or "alias-token" (alias-token is parsed on server side, full string is used as-is here)
    api_key = ENV.fetch("EMAIL_REST_APIKEY", nil)
    raise ArgumentError, "EMAIL_REST_APIKEY environment variable is required" unless api_key.present?

    creds = Base64.strict_encode64("api:#{api_key}")
    "Basic #{creds}"
  end
end
