# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

gem "decidim", "0.25.0"
gem "decidim-consultations", "0.25.0"
gem "decidim-initiatives", "0.25.0"
gem "decidim-conferences", "0.25.0"
# gem "decidim-templates", "0.23.1"
gem "decidim-anonymous_proposals", git: "https://github.com/PopulateTools/decidim-module-anonymous_proposals", branch: "release/0.25"
gem "decidim-extra_user_fields", git: "https://github.com/PopulateTools/decidim-module-extra_user_fields", branch: "release/0.25"

gem "decidim-term_customizer", "~> 0.24.0", git: "https://github.com/mainio/decidim-module-term_customizer.git"

gem "bootsnap", "~> 1.3"

gem "puma", ">= 5.0"
gem "uglifier", "~> 4.1"

gem "faker", "~> 1.9"

gem "faraday"
gem "wicked_pdf", "~> 1.4"
gem "sidekiq", "~> 5.2"
gem "letter_opener_web", "~> 1.3"
gem "virtus-multiparams"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri

  gem "decidim-dev", "0.25.0"
end

group :development do
  gem "letter_opener_web", "~> 1.3"
  gem "listen", "~> 3.1"
  gem "spring", "~> 2.0"
  gem "spring-watcher-listen", "~> 2.0"
  gem "web-console", "~> 3.5"
end
