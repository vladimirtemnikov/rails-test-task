# frozen_string_literal: true

source 'https://rubygems.org'

ruby file: '.ruby-version'

gem 'rails', '~> 8.1.1'

gem 'pg'

gem 'bootsnap', require: false
gem 'debug', require: 'debug/prelude'

gem 'aasm'
gem 'action_policy'
gem 'devise'
gem 'propshaft'
gem 'puma'
gem 'simple_form'
gem 'slim'
gem 'solid_queue'

group :development do
  gem 'brakeman', require: false
  gem 'bundler-audit', require: false
  gem 'listen'

  gem 'rubocop'
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rspec_rails', require: false
end

group :test do
  gem 'factory_bot_rails'
  gem 'rspec-rails'
end
