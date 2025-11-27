# frozen_string_literal: true

require "mail_webservice_handler"
ActionMailer::Base.add_delivery_method :webservice, MailWebserviceHandler
