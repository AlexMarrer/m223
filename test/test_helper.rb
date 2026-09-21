ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Minimal valid attributes for a draft concert. Tests override what they care about.
    def concert_attributes(**attributes)
      starts_at = 1.week.from_now.change(usec: 0)

      {
        creator: users(:organizer),
        title: "Testkonzert",
        capacity: 2,
        starts_at: starts_at,
        ends_at: starts_at + 2.hours
      }.merge(attributes)
    end
  end
end
