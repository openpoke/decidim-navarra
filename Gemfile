# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION
DECIDIM_VERSION = "0.29.2"

gem "decidim", DECIDIM_VERSION
gem "decidim-anonymous_proposals", git: "https://github.com/PopulateTools/decidim-module-anonymous_proposals"
gem "decidim-conferences", DECIDIM_VERSION
gem "decidim-initiatives", DECIDIM_VERSION
gem "decidim-templates", DECIDIM_VERSION

gem "bootsnap", "~> 1.4"
gem "decidim-decidim_awesome", github: "decidim-ice/decidim-module-decidim_awesome", branch: "main"
gem "decidim-term_customizer", github: "CodiTramuntana/decidim-module-term_customizer", branch: "upgrade/decidim_0.29"

gem "deface", ">= 1.9"
gem "faraday"
gem "foundation_rails_helper", git: "https://github.com/sgruhier/foundation_rails_helper.git"
gem "health_check"
gem "puma", ">= 5.3.1"
gem "sidekiq", "~> 5.2"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri
  gem "faker", "~> 3.2"

  gem "decidim-dev", DECIDIM_VERSION

  gem "brakeman", "~> 5.1"
end

group :development do
  gem "letter_opener_web"
  gem "listen"
  gem "rubocop-faker"
end
