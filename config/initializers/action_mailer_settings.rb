# frozen_string_literal: true

case ENV.fetch("MAILER_DELIVERY_METHOD", nil)
when "webservice"
  require "mail_webservice_handler"
  ActionMailer::Base.add_delivery_method :webservice, MailWebserviceHandler
when "sendmail_rest"
  require "sendmail_rest_handler"
  ActionMailer::Base.add_delivery_method :sendmail_rest, SendmailRestHandler
end
