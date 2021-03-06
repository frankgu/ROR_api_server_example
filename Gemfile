# frozen_string_literal: true

ruby '2.3.3'

source 'https://rubygems.org'

gem 'bcrypt', '~> 3.1', '>= 3.1.11'
gem 'config', '~> 1.4'
gem 'http', '~> 2.2', '>= 2.2.2'
gem 'i18n', '~> 0.8.4'
gem 'pg', '~> 0.21.0'
gem 'pingpp', '~> 2.1'
gem 'puma', '~> 3.9', '>= 3.9.1'
gem 'rails', '~> 5.1', '>= 5.1.2'
gem 'redis', '~> 3.3', '>= 3.3.1'
gem 'sdoc', '~> 0.4.2', group: :doc
gem 'sidekiq', '~> 5.0', '>= 5.0.3'
gem 'sidekiq-status', '~> 0.6.0'
gem 'wisper', '~> 2.0'
gem 'wisper-sidekiq', '~> 0.0.1'
# Making it easy to serialize models for client-side use
gem 'active_model_serializers', '~> 0.10.0'
# API Document gem
gem 'apipie-rails', '~> 0.5.1'
# Encoding and decoding the HMACSHA256 token
gem 'jwt', '~> 1.5', '>= 1.5.4'
# Build an use Service Objects in Ruby for authentication
gem 'simple_command', '~> 0.0.9'
# Twilio video communication
gem 'twilio-ruby', '~> 5.1', '>= 5.1.2'

group :production do
  gem 'rails_12factor', '~> 0.0.3'
end

group :test do
  gem 'simplecov', require: false
end

group :development, :test do
  gem 'factory_girl_rails', '~> 4.8'
  gem 'rspec-rails', '~> 3.6'
end

group :development do
  gem 'listen', '~> 3.0.5'
  gem 'rails-erd'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
