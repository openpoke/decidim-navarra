# frozen_string_literal: true

if Rails.application.secrets.mailer_delivery_method == "smtp"
  Rails.application.config.action_mailer.delivery_method = :smtp
  Rails.application.config.action_mailer.smtp_settings = {
    address: Rails.application.secrets.smtp_address,
    port: Rails.application.secrets.smtp_port,
    authentication: Rails.application.secrets.smtp_authentication,
    user_name: Rails.application.secrets.smtp_username,
    password: Rails.application.secrets.smtp_password,
    domain: Rails.application.secrets.smtp_domain,
    enable_starttls_auto: Rails.application.secrets.smtp_starttls_auto,
    openssl_verify_mode: "none"
  }
elsif Rails.application.secrets.mailer_delivery_method == "webservice"
  Rails.application.config.action_mailer.delivery_method = :webservice
  ::ActionMailer::Base.add_delivery_method :webservice, MailWebserviceHandler
end
