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

    # Monday is the first day of the week, Sunday the last. This is the Rails default;
    # pinned explicitly because task 6 groups concerts by week.
    config.beginning_of_week = :monday

    # Render a form field with errors exactly as written, without ActionView's
    # <div class="field_with_errors"> wrapper. Validation messages are listed centrally in the
    # form-errors block; marking single fields invalid is done explicitly in the form that
    # needs it, not through a global wrapper.
    config.action_view.field_error_proc = proc { |html_tag, _instance| html_tag }

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
