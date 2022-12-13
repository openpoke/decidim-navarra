# frozen_string_literal: true

require "bcrypt"

namespace :anonymize do

  def with_progress(collection, name:)
    total = collection.count
    progressbar = create_progress_bar(total: total)

    puts "Anonymizing #{total} #{name}...\n"
    skip_logs do
      collection.find_each do |item|
        yield(item)
        progressbar.increment
      end
    end
  end

  def create_progress_bar(total:)
    ProgressBar.create(
      progress_mark:  " ",
      remainder_mark: "\u{FF65}",
      total: total,
      format: "%a %e %b\u{15E7}%i %p%% %t"
    )
  end

  def skip_logs
    previous_log_level = ActiveRecord::Base.logger.level
    ActiveRecord::Base.logger.level = 2
    yield
    ActiveRecord::Base.logger.level = previous_log_level
  end

  def default_organization
    ::Decidim::Organization.first
  end

  def default_password
    "deciPass123456"
  end

  def default_encrypted_password
    ::BCrypt::Password.create(default_password, cost: 1).to_s
  end

  def default_user_attributes
    {
      organization: default_organization,
      password: default_password,
      password_confirmation: default_password,
      confirmed_at: Time.zone.now,
      newsletter_notifications: true,
      email_on_notification: true,
      tos_agreement: true
    }
  end

  desc "Checks for the environment"
  task :check do
    raise "Won't run unless the env var DISABLE_PRODUCTION_CHECK=1 is set" unless ENV["DISABLE_PRODUCTION_CHECK"]
    raise "Can't run this task in production environment" if Rails.env.production?
  end

  desc "Anonymizes a production dump."
  task all: %i(users user_groups create_default_users)

  task users: [:check, :environment] do
    Decidim::User.where.not("email ~* ?", "@(navarra\.es)").where.not("email ~* ?", "@(populate\.tools)").find_each do |user|
      user.update_columns(
        email: "user-#{user.id}@example.com",
        name: "Anonymized User #{user.id}",
        encrypted_password: default_encrypted_password,
        reset_password_token: nil,
        current_sign_in_at: nil,
        last_sign_in_at: nil,
        current_sign_in_ip: nil,
        last_sign_in_ip: nil,
        invitation_token: nil,
        confirmation_token: nil,
        unconfirmed_email: nil
      )

      Decidim::Authorization.where(user: user).find_each do |authorization|
        authorization.update_columns(unique_id: authorization.id)
      end
    end
  end

  task user_groups: [:check, :environment] do
    Decidim::UserGroup.find_each do |user_group|
      user_group.update_columns(
        name: "User Group #{user_group.id}"
      )
    end
  end

  task create_default_users: [:check, :environment] do
    ::Decidim::User.create!(default_user_attributes.merge(
      email: "user@decidim.dev",
      name: "Regular User",
      nickname: "regular-user",
      admin: false
    ))

    ::Decidim::User.create!(default_user_attributes.merge(
      email: "admin@decidim.dev",
      name: "Admin User",
      nickname: "admin-user",
      admin: true
    ))
  end
end
