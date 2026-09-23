require "test_helper"

# The multi-user case from docs/spec/PROJECT.md: two valid attempts on the last seat may produce
# exactly one registration. What protects it is the transaction, which SQLite opens as
# BEGIN IMMEDIATE, so these tests have to reach the database the way two requests would.
class ConcertConcurrencyTest < ActiveSupport::TestCase
  # A test normally runs inside one transaction, which would hold the write lock for its whole
  # duration and let the second attempt wait for something that never commits.
  self.use_transactional_tests = false

  # There are no concert, registration or activity fixtures, so the rows created here are the
  # only ones. Activities reference concerts, so they go first.
  teardown do
    Activity.delete_all
    Registration.delete_all
    Concert.delete_all
  end

  test "two simultaneous attempts for the last seat create exactly one registration" do
    concert = Concert.create!(published_concert_attributes(capacity: 1))

    results = race(users(:one), users(:two)) do |user|
      Concert.find(concert.id).register(user).persisted?
    end

    assert_equal 1, results.count(true), "exactly one attempt may succeed"
    assert_equal 1, concert.reload.registrations.count
  end

  test "a capacity reduction running against a booking never overbooks the concert" do
    concert = Concert.create!(published_concert_attributes(capacity: 2))
    concert.register(users(:one))

    results = race(:reduce_capacity, :book) do |operation|
      fresh = Concert.find(concert.id)

      if operation == :reduce_capacity
        fresh.apply_changes({ capacity: 1 }, actor: users(:organizer))
      else
        fresh.register(users(:two)).persisted?
      end
    end

    concert.reload
    assert_equal 1, results.count(true), "the loser of the race has to be rejected"
    assert_operator concert.registrations.count, :<=, concert.capacity
  end

  private
    # Runs the block once per argument, each on its own database connection, released at the same
    # moment. Every occupancy count is delayed so that both attempts read before either writes —
    # without that window the two transactions would simply run one after the other and the test
    # would pass even with the protection removed.
    def race(*arguments)
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        sleep 0.2 if payload[:sql].include?('COUNT(*) FROM "registrations"')
      end

      gate = Queue.new
      results = []
      mutex = Mutex.new

      threads = arguments.map do |argument|
        Thread.new do
          gate.pop

          ActiveRecord::Base.connection_pool.with_connection do
            result = yield argument
            mutex.synchronize { results << result }
          end
        end
      end

      arguments.size.times { gate << :go }
      threads.each(&:join)
      results
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end
end
