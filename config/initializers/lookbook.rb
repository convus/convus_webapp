# https://lookbook.build/guide/ui/theming

if defined?(Lookbook)
  Lookbook.configure do |config|
    config.ui_theme = "blue"
    config.preview_paths = ["#{Rails.root}/app/components/"]
  end
end
