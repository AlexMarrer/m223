require "test_helper"

# The transaction brackets of docs/spec/PROJECT.md, section "Transactions": every logged use case
# writes exactly one activity, and it writes it inside the transaction of the business change.
class ActivityLoggingTest < ActiveSupport::TestCase
  setup do
    @organizer = users(:organizer)
    @participant = users(:one)
  end

  test "a registration is logged with the participant as actor" do
    concert = published_concert

    assert_difference -> { Activity.count }, 1 do
      concert.register(@participant)
    end

    activity = Activity.last
    assert_equal "registered", activity.action
    assert_equal @participant, activity.actor
    assert_equal concert, activity.concert
    assert_empty activity.details, "an action without changed fields carries no details"
  end

  test "a rejected registration is not logged" do
    full = published_concert(capacity: 1)
    full.register(users(:two))
    draft = Concert.create!(concert_attributes)

    assert_no_difference -> { Activity.count } do
      full.register(@participant)
      full.register(users(:two))
      draft.register(@participant)
    end
  end

  test "a cancellation is logged with the participant as actor" do
    concert = published_concert
    registration = concert.register(@participant)

    assert_difference -> { Activity.count }, 1 do
      assert registration.withdraw
    end

    activity = Activity.last
    assert_equal "cancelled_registration", activity.action
    assert_equal @participant, activity.actor
    assert_equal concert, activity.concert
  end

  test "a rejected cancellation is not logged" do
    concert = published_concert
    registration = concert.register(@participant)
    concert.cancel(@organizer)

    assert_no_difference -> { Activity.count } do
      assert_not registration.withdraw
    end
  end

  test "publishing is logged with the acting organizer" do
    concert = Concert.create!(concert_attributes(description: "Beschreibung", setlist: "Lied eins"))

    assert_difference -> { Activity.count }, 1 do
      assert concert.publish(@organizer)
    end

    activity = Activity.last
    assert_equal "published", activity.action
    assert_equal @organizer, activity.actor
    assert_equal concert, activity.concert
  end

  test "a rejected publication is not logged" do
    incomplete = Concert.create!(concert_attributes)

    assert_no_difference -> { Activity.count } do
      assert_not incomplete.publish(@organizer)
    end
  end

  test "the Absage of a concert is logged" do
    concert = published_concert

    assert_difference -> { Activity.count }, 1 do
      assert concert.cancel(@organizer)
    end

    activity = Activity.last
    assert_equal "cancelled_concert", activity.action
    assert_equal @organizer, activity.actor
  end

  test "a rejected Absage is not logged" do
    draft = Concert.create!(concert_attributes)

    assert_no_difference -> { Activity.count } do
      assert_not draft.cancel(@organizer)
    end
  end

  test "a change to a published concert is logged with old and new values" do
    concert = published_concert(capacity: 2)

    assert_difference -> { Activity.count }, 1 do
      assert concert.apply_changes({ capacity: 5 }, actor: @organizer)
    end

    activity = Activity.last
    assert_equal "updated", activity.action
    assert_equal @organizer, activity.actor
    assert_equal({ "capacity" => { "old" => 2, "new" => 5 } }, activity.details)
  end

  test "several fields changed at once produce one activity covering all of them" do
    concert = published_concert

    assert_difference -> { Activity.count }, 1 do
      concert.apply_changes({ title: "Neuer Titel", capacity: 5, setlist: "Lied zwei" },
                            actor: @organizer)
    end

    details = Activity.last.details
    assert_equal %w[ capacity setlist title ], details.keys.sort
    assert_equal({ "old" => "Testkonzert", "new" => "Neuer Titel" }, details["title"])
  end

  test "an edit of a draft is not logged" do
    draft = Concert.create!(concert_attributes)

    assert_no_difference -> { Activity.count } do
      assert draft.apply_changes({ title: "Anderer Entwurf" }, actor: @organizer)
    end
  end

  test "an update that changes nothing is not logged" do
    concert = published_concert

    assert_no_difference -> { Activity.count } do
      assert concert.apply_changes({ title: concert.title }, actor: @organizer)
    end
  end

  test "a rejected update is not logged" do
    concert = published_concert(capacity: 2)
    concert.register(@participant)
    concert.register(users(:two))

    assert_no_difference -> { Activity.count } do
      assert_not concert.apply_changes({ capacity: 1 }, actor: @organizer)
    end
  end

  test "a failing activity rolls back the registration" do
    concert = published_concert

    with_failing_activities(concert) do
      assert_raises(ActiveRecord::RecordInvalid) { concert.register(@participant) }
    end

    assert_equal 0, concert.reload.registrations.count
    assert_equal 0, Activity.count
  end

  test "a failing activity rolls back the concert change" do
    concert = published_concert

    with_failing_activities(concert) do
      assert_raises(ActiveRecord::RecordInvalid) do
        concert.apply_changes({ title: "Nicht gespeichert" }, actor: @organizer)
      end
    end

    assert_equal "Testkonzert", concert.reload.title
    assert_equal 0, Activity.count
  end

  test "a failing activity rolls back the Storno" do
    concert = published_concert
    registration = concert.register(@participant)

    with_failing_activities(concert) do
      assert_raises(ActiveRecord::RecordInvalid) { registration.withdraw }
    end

    assert Registration.exists?(registration.id), "the cancelled seat has to come back"
    assert_equal 1, concert.reload.registrations.count
    assert_equal 1, Activity.count, "only the registration of the setup may remain"
  end

  test "a failing activity rolls back the publication" do
    concert = Concert.create!(concert_attributes(description: "Beschreibung", setlist: "Lied eins"))

    with_failing_activities(concert) do
      assert_raises(ActiveRecord::RecordInvalid) { concert.publish(@organizer) }
    end

    assert concert.reload.draft?
    assert_equal 0, Activity.count
  end

  test "a failing activity rolls back the Absage" do
    concert = published_concert

    with_failing_activities(concert) do
      assert_raises(ActiveRecord::RecordInvalid) { concert.cancel(@organizer) }
    end

    assert concert.reload.published?
    assert_equal 0, Activity.count
  end

  private
    def published_concert(**attributes)
      Concert.create!(published_concert_attributes(**attributes))
    end

    # Replaces this one concert's activities with a collection that refuses to save. The activity
    # write is the last step of every use case, so this is what proves the business change goes
    # with it. Only the in-memory object the test discards afterwards is touched.
    def with_failing_activities(concert)
      failing = Class.new do
        def create!(*)
          raise ActiveRecord::RecordInvalid.new(Activity.new)
        end
      end.new

      concert.define_singleton_method(:activities) { failing }

      yield
    end
end
