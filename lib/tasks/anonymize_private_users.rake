# frozen_string_literal: true

require "bcrypt"

namespace :anonymize_private_users do
  def random_password
    Decidim::Tokenizer.random_salt
  end

  def random_encrypted_password
    ::BCrypt::Password.create(random_password, cost: 1).to_s
  end

  desc "Anonymize and delete users that have been invited to private space but not accepted the invitation to participate"
  task :remove_private_space_invited_users, [:participatory_space_type, :slug] => [:environment] do |_t, args|
    raise "Please, provide a participatory process type and slug" if [args[:participatory_space_type], args[:slug]].all?(&:blank?)

    participatory_space_type = args[:participatory_space_type]
    slug = args[:slug]
    participatory_space = participatory_space_type.constantize.find_by(slug: slug)
    private_users = Decidim::ParticipatorySpacePrivateUser.by_participatory_space(participatory_space).joins(:user).where(user: { invitation_accepted_at: nil })

    puts "\n\n No users found." if private_users.blank?

    private_users.each do |private_user|
      user = private_user.user

      if user.deleted?
        puts "\n\nUser #{user.email} already deleted, skipped."
        next
      end

      puts "\n\nDeleting user #{user.email}..."

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

      user.delete_reason = "Inactive private space user"
      user.admin = false if user.admin?
      user.deleted_at = Time.current
      user.skip_reconfirmation!
      user.avatar.purge
      user.save!

      puts "User deleted."
    end
  end
end
