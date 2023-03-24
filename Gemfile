# frozen_string_literal: true

source 'https://rubygems.org'

ruby '2.6.5'

gem 'rails', '5.2.6.2'
gem 'rake'

# Object state management
gem 'state_machines-activerecord'

# XML-RPC/SOAP
gem 'savon'
gem 'wash_out'

# Pagination
gem 'kaminari'

# Authentication
gem 'devise'
gem 'oauth'

# Error handling
gem 'sentry-raven'
gem 'appsignal'

# Image / File processing
gem 'activestorage-openstack'
gem 'barby'
gem 'chunky_png' # required by barby
gem 'mini_magick'
gem 'paperclip'
gem 'prawn'
gem 'prawn-qrcode'
gem 'prawn-table'

# View render and utils
gem 'nested_form'
gem 'simple_form'

# System libraries binding
gem 'gio2', '3.4.9'
gem 'gobject-introspection', '3.4.9'
gem 'cairo-gobject', '3.4.9'
gem 'poppler', '3.4.9'
gem 'glib2'

# Object renderer
gem 'rabl'

# Query & Network management
gem 'net-sftp'
gem 'typhoeus' #used by MCF and Slimpay requests
gem 'faraday'
gem 'faraday_middleware'

# Cache
gem 'dalli'

# Deployment
gem 'bcrypt_pbkdf'
gem 'capistrano'
gem 'capistrano-rails'
gem 'capistrano-rvm'
gem 'capistrano-slackify'
gem 'capistrano_colors', require: false
gem 'ed25519'
gem 'net-ssh', '7.0.1'

# Validators
gem 'validate_url'

# Processes management
gem 'posix-spawn'

# Console tools
gem 'hirb', require: false

# Assets management
gem 'mini_racer'
gem 'sprockets'
gem 'sprockets-rails'
gem 'uglifier'

# CSS Libraries and CSS Processors
gem 'bootstrap', '~> 5.0.1'
gem 'compass-rails'
gem 'sass-rails'

# JS Libraries and JS processors
gem 'coffee-rails'
gem 'eco'
gem 'jquery-rails'
gem 'jquery-ui-rails'

# Frontend tools
gem 'bootstrap-datepicker-rails'
gem 'momentjs-rails'
gem 'bootstrap-daterangepicker-rails'
gem 'ckeditor'
gem 'haml'

# Charts
gem 'd3_rails'

# DB Adapter
gem 'mysql2'

# Scheduling Jobs
gem 'sidekiq', '5.2.7'
gem 'sidekiq-scheduler'
gem 'sidekiq-unique-jobs'

# Data format
gem 'ansi', require: false
gem 'axlsx'
gem 'bson'
gem 'hpricot'
gem 'nokogiri'
gem 'oj'
gem 'to_xls'

# External services
gem 'dropbox_api'
gem 'google-api-client'
gem 'google_drive'
gem 'ruby-box'
gem 'bridge_bankin', '0.1.8'

# Lock mechanism
gem 'remote_lock'

# Encryption
gem 'symmetric-encryption'

# Metric
# gem 'skylight'

gem 'redcarpet'

# Audit
gem 'audited'

gem 'ruby-progressbar', require: false

# Boot
gem 'bootsnap'

# JSON Serialization
gem 'fast_jsonapi'

# Cache
gem 'redis-rails'
gem 'activerecord-session_store'

# API DOC
gem 'rswag-api'
gem 'rswag-ui'
gem 'rswag-specs'
gem 'rspec-rails'

group :development, :test do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'bullet'
  gem 'byebug'
  gem 'guard-livereload', require: false
  gem 'libnotify'
  gem 'meta_request'
  gem 'rack-mini-profiler'
  gem 'rails-i18n'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'thin'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'ftpd', require: false
  gem 'guard-rspec', require: false
  gem 'simplecov', require: false
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
end