require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module M223
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # The UI is German; code and identifiers stay English.
    config.i18n.default_locale = :de

    # Monday is the first day of the week, Sunday the last. This is the Rails default; pinned
    # explicitly because the German date output relies on it.
    config.beginning_of_week = :monday

    # Render a field with errors exactly as written, without ActionView's field_with_errors
    # wrapper. Validation messages are listed centrally in the form-errors block instead.
    config.action_view.field_error_proc = proc { |html_tag, _instance| html_tag }
  end
end
