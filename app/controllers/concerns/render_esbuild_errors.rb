module RenderEsbuildErrors
  extend ActiveSupport::Concern
  ERROR_FILE = "esbuild_error"

  def self.file_path
    Rails.root.join(ERROR_FILE)
  end

  def self.enabled?
    Rails.env.development? || Rails.env.test? && ENV["ESBUILD_ERROR_RENDERED"].present?
  end

  included do
    before_action :render_esbuild_error_if_present, if: -> { RenderEsbuildErrors.enabled? }
  end

  def render_esbuild_error_if_present
    return unless esbuild_error_present?

    heading, errors = error_file_content.split("\n", 2)

    # Render error as HTML so rack-livereload can inject its code into <head>
    # and refresh the error page when assets are modified.
    render html: <<~HTML.html_safe, layout: false
      <html>
        <head></head>
        <body>
          <h1>#{ERB::Util.html_escape(heading)}</h1>
          <pre>#{ERB::Util.html_escape(errors)}</pre>
        </body>
      </html>
    HTML
  end

  private

  def error_file_content
    file_path = RenderEsbuildErrors.file_path
    File.exist?(file_path) ? file_path.read : ""
  end

  def esbuild_error_present?
    error_file_content.size > 0
  end
end
