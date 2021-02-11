# frozen_string_literal: true

namespace :decidim_navarra do

  desc "Initialize site and create and admin and a user"
  task :initialize_site, [:host] => [:environment] do |_t, args|
    host = args[:host] || ENV["DECIDIM_HOST"] ||"localhost"
    smtp_label = "Participación Ciudadana"
    smtp_email = "participacionciudadana@navarra.es"
    seeds_root = File.join(__dir__, "..", "..", "db", "seeds")

    organization = Decidim::Organization.first || Decidim::Organization.create!(
      name: "Participación Ciudadana",
      twitter_handler: "https://twitter.com/navarra",
      facebook_handler: "NavarraInfoCiudadana",
      youtube_handler: "user/GobiernoNavarra",
      smtp_settings: {
        from: "#{smtp_label} <#{smtp_email}>",
        from_email: smtp_email,
        from_label: smtp_label,
        user_name: smtp_label,
        encrypted_password: Decidim::AttributeEncryptor.encrypt("test1234"),
        address: host,
        port: ENV["DECIDIM_SMTP_PORT"] || "25"
      },
      host: host,
      default_locale: Decidim.default_locale,
      available_locales: Decidim.available_locales,
      reference_prefix: "PCN",
      available_authorizations: Decidim.authorization_workflows.map(&:name),
      users_registration_mode: :enabled,
      tos_version: Time.current,
      badges_enabled: true,
      user_groups_enabled: true,
      send_welcome_notification: true,
      file_upload_settings: Decidim::OrganizationSettings.default(:upload)
    )

    admin = Decidim::User.find_or_initialize_by(email: "admin@example.org")

    admin.update!(
      name: "Admin",
      nickname: "admin",
      password: "decidim123456",
      password_confirmation: "decidim123456",
      organization: organization,
      confirmed_at: Time.current,
      locale: I18n.default_locale,
      admin: true,
      tos_agreement: true,
      accepted_tos_version: organization.tos_version,
      admin_terms_accepted_at: Time.current
    )

    regular_user = Decidim::User.find_or_initialize_by(email: "user@example.org")

    regular_user.update!(
      name: "Usuario",
      nickname: "user",
      password: "decidim123456",
      password_confirmation: "decidim123456",
      confirmed_at: Time.current,
      locale: I18n.default_locale,
      organization: organization,
      tos_agreement: true,
      accepted_tos_version: organization.tos_version
    )

    Decidim::System::CreateDefaultContentBlocks.call(organization)

    hero_content_block = Decidim::ContentBlock.find_by(organization: organization, manifest_name: :hero, scope_name: :homepage)
    hero_content_block.images_container.background_image = File.new(File.join(seeds_root, "homepage_image.jpg"))
    settings = {}
    welcome_text = { "es" => "Escucha. Participa. Conversa", "eu" => "Entzun, Parte hartu. Elkarrizketak eduki" }
    settings = welcome_text.inject(settings) { |acc, (k, v)| acc.update("welcome_text_#{k}" => v) }
    hero_content_block.settings = settings
    hero_content_block.save!
  end

  desc "Transforms a CSV of processes and imports it in a organization"
  task :import, [:csv_path, :organization_id, :admin_id] => [:environment] do |_t, args|
    raise "Please, provide a file path" if args[:csv_path].blank?

    organization = Decidim::Organization.find_by(id: args[:organization_id]) || Decidim::Organization.first
    admin = args[:admin_id].present? ? organization.admins.find_by(id: args[:admin_id]) : organization.admins.first

    puts "Importing processes, please wait..."
    importer = ProcessesImporter.new(args[:csv_path], organization, admin)
    importer.import_processes
    puts "Import completed."
  end
end
