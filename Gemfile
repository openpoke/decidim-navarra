# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION
DECIDIM_VERSION = { github: "openpoke/decidim", branch: "0.31-backports" }.freeze

gem "decidim", DECIDIM_VERSION
gem "decidim-anonymous_proposals", github: "openpoke/decidim-module-anonymous_proposals", branch: "main"
gem "decidim-collaborative_texts", DECIDIM_VERSION
gem "decidim-conferences", DECIDIM_VERSION
gem "decidim-elections", DECIDIM_VERSION
gem "decidim-initiatives", DECIDIM_VERSION
gem "decidim-templates", DECIDIM_VERSION

gem "bootsnap"
gem "decidim-decidim_awesome", github: "decidim-ice/decidim-module-decidim_awesome", branch: "main"
gem "decidim-pokecode", github: "openpoke/decidim-module-pokecode", branch: "main"
gem "decidim-term_customizer", github: "openpoke/decidim-module-term_customizer", branch: "main"

gem "faraday"
gem "faraday-multipart"
gem "puma"

group :development, :test do
  gem "byebug"
  gem "faker"

  gem "brakeman"
  gem "decidim-dev", DECIDIM_VERSION
end

group :development do
  gem "letter_opener_web"
  gem "rubocop-faker"
end
