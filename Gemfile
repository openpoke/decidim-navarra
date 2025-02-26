# frozen_string_literal: true

source 'https://rubygems.org'

ruby RUBY_VERSION
DECIDIM_VERSION = '0.29.2'

gem 'decidim', DECIDIM_VERSION
gem 'decidim-anonymous_proposals', git: 'https://github.com/PopulateTools/decidim-module-anonymous_proposals'
gem 'decidim-conferences', DECIDIM_VERSION
gem 'decidim-initiatives', DECIDIM_VERSION
gem 'decidim-templates', DECIDIM_VERSION

# gem "decidim-term_customizer", git: "https://github.com/mainio/decidim-module-term_customizer.git"
gem 'decidim-decidim_awesome', github: 'decidim-ice/decidim-module-decidim_awesome', branch: 'upgrade-0.29'

gem 'bootsnap', '~> 1.4'

# gem "foundation_rails_helper", git: "https://github.com/sgruhier/foundation_rails_helper.git"
gem 'puma', '>= 5.3.1'

gem 'faker', '~> 3.2'

gem 'faraday'
gem 'nokogiri', '~> 1.12'
gem 'sidekiq', '~> 5.2'
gem 'wicked_pdf', '~> 2.1'

group :development, :test do
  gem 'byebug', '~> 11.0', platform: :mri

  gem 'simplecov', '~> 0.22.0'

  gem 'decidim-dev', DECIDIM_VERSION

  gem 'brakeman', '~> 5.1'
end

group :development do
  gem 'letter_opener_web', '~> 1.3'
  gem 'listen', '~> 3.1'
  gem 'rubocop-faker'
  gem 'spring'
  gem 'spring-watcher-listen'
end
