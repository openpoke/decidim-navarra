# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION
DECIDIM_VERSION = "0.26.9"

gem "decidim", DECIDIM_VERSION
gem "decidim-conferences", DECIDIM_VERSION
gem "decidim-consultations", DECIDIM_VERSION
gem "decidim-initiatives", DECIDIM_VERSION
# gem "decidim-templates", "0.23.1"
gem "decidim-anonymous_proposals", git: "https://github.com/PopulateTools/decidim-module-anonymous_proposals", branch: "release/0.26-stable"

gem "decidim-term_customizer", git: "https://github.com/mainio/decidim-module-term_customizer.git", branch: "release/0.26-stable"
gem "decidim-decidim_awesome", "~> 0.8"

gem "bootsnap", "~> 1.4"

gem "foundation_rails_helper", git: "https://github.com/sgruhier/foundation_rails_helper.git"
gem "puma", ">= 5.3.1"

gem "faker", "~> 2.14"

gem "faraday"
gem "wicked_pdf", "~> 2.1"
gem "sidekiq", "~> 5.2"
gem "virtus-multiparams"
gem "nokogiri", "~> 1.12"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri

  gem "simplecov", "~> 0.19.0"

  gem "decidim-dev", DECIDIM_VERSION

  gem "brakeman", "~> 5.1"
end

group :development do
  gem "letter_opener_web", "~> 1.3"
  gem "listen", "~> 3.1"
  gem "rubocop-faker"
  gem "spring"
  gem "spring-watcher-listen"
end
