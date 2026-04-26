source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "4.0.2"

gem "rails"

gem "puma" # Use Puma as the app server
gem "thruster", require: false # Asset compression and caching for Puma
gem "kamal", require: false # Deploy with Kamal
gem "rack-cors" # Make cors requests

# database stuff
gem "pg" # Use postgresql as the database for Active Record

# Redis, redis requirements
gem "redis" # Redis itself
gem "observer" # Required for Ruby 3.4+ (removed from stdlib)
gem "csv" # Required for Ruby 3.4+ (removed from stdlib)
gem "sidekiq" # Background job processing (with redis)
gem "connection_pool", "< 3" # temporary - see github.com/mperham/connection_pool/issues/212
gem "sinatra" # Used for sidekiq web
gem "sidekiq-failures" # Show sidekiq failures
gem "sidekiq-logstash" # Better sidekiq logging
gem "redlock" # Locking, to handle API rate limiting

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

gem "devise" # Users

gem "pagy" # Pagination
gem "faraday" # How we make requests for integrations

gem "commonmarker" # parse markdown

# Make logging - more useful and ingestible
gem "lograge", ">= 0.14" # Structure log data, put it in single lines to improve the functionality
gem "logstash-event" # Use logstash format for logging data

# Frontend things
gem "chartkick" # Display charts
gem "groupdate" # Required for charts
gem "hamlit" # Faster haml templates
gem "premailer-rails" # Inline styles for email
gem "coderay" # For pretty printing JSON

# New shiny frontend stuff
gem "propshaft" # For Assets Pipeline
gem "tailwindcss-rails" # Tailwind CSS via standalone binary
gem "importmap-rails" # Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "hotwire-livereload" # Livereload!
gem "turbo-rails" # Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "stimulus-rails"
gem "binxtils" # Bike Index utilities
gem "view_component" # View components

group :production, :staging do
  gem "honeybadger" # Error reporting
  # gem "skylight" # Performance, add when needed
end

group :development, :test do
  gem "brakeman", require: false
  gem "foreman" # Process runner for local work
  gem "dotenv-rails" # Add environmental variables for importing things
  gem "rspec-rails" # Test framework
  gem "factory_bot_rails" # mocking/stubbing
  gem "rubocop"
  gem "standard" # Ruby linter
  gem "turbo_tests" # Parallel test execution
end

group :development, :test do
  gem "lookbook" # Component previews
end

group :development do
  # gem "web-console", ">= 3.3.0" # Access an interactive console on exception pages or by calling "console" anywhere in the code - commented out because annoying
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "rerun" # For restarting sidekiq on file changes
  gem "letter_opener" # For displaying emails in development
end

group :test do
  gem "guard", require: false
  gem "guard-rspec", require: false
  gem "rspec_junit_formatter" # For circle ci
  gem "rspec-github", require: false # Rspec GitHub formatter (adds annotations to files)
  gem "rails-controller-testing" # Assert testing views
  gem "rspec-retry", require: false # Retry flaky test failures on CI
  # gem "simplecov", require: false # test coverage for Ruby
  # gem "timecop" # Time control
  gem "vcr" # Stub external HTTP requests
  gem "webmock" # mocking for VCR
  gem "capybara" # For view component system specs
  gem "selenium-webdriver" # Browser driver for system specs
  gem "axe-core-rspec" # Accessibility testing
  gem "super_diff" # Better test output diffs
end

# Performance Stuff
gem "fast_blank" # high performance replacement String#blank? a method that is called quite frequently in ActiveRecord
gem "flamegraph", require: false
gem "stackprof", require: false # Required by flamegraph
gem "rack-mini-profiler", require: ["prepend_net_http_patch"] # If you can't see it you can't make it better
gem "bootsnap", ">= 1.1.0", require: false # Reduces boot times through caching; required in config/boot.rb
