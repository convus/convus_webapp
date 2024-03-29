require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Livereload, via hotwire-livereload. Hopefully it gets into rails core?
  config.hotwire_livereload.listen_paths << Rails.root.join("app/assets/stylesheets")

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :redis_cache_store, {url: config.redis_cache_url}
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Lograge is used in production
  unless Rails.root.join("tmp", "non-lograge-dev.txt").exist?
    config.lograge.enabled = true
    config.log_level = :debug
    config.lograge.formatter = Lograge::Formatters::Logstash.new # Use logstash format
    config.lograge.custom_options = lambda do |event|
      {
        remote_ip: event.payload[:ip],
        params: event.payload[:params]&.except("controller", "action", "format", "id")
      }
    end
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  # config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # TODO: handle setting this better - shouldn't need to specify twice?
  Rails.application.routes.default_url_options[:host] = "http://localhost:3009"
  config.action_mailer.default_url_options = {host: "localhost", port: 3009}
  if Rails.root.join("tmp", "skip-letter_opener.txt").exist?
    config.action_mailer.perform_deliveries = false
    config.action_mailer.delivery_method = :smtp
  else
    config.action_mailer.perform_deliveries = true
    config.action_mailer.delivery_method = :letter_opener
  end

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Don't report errors to honeybadger, etc
  config.error_reporting_behavior = :sandbox
end
