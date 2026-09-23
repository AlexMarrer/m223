require "test_helper"

class ConcertTest < ActiveSupport::TestCase
  test "is valid as a draft without description and setlist" do
    concert = Concert.new(concert_attributes)
    assert concert.valid?
    assert concert.draft?
  end

  test "belongs to its creator" do
    concert = Concert.create!(concert_attributes(creator: users(:admin)))
    assert_equal users(:admin), concert.creator
    assert_includes users(:admin).created_concerts, concert
  end

  test "requires a title" do
    concert = Concert.new(concert_attributes(title: ""))
    assert_not concert.valid?
    assert_includes concert.errors.attribute_names, :title
  end

  test "rejects zero or negative capacity" do
    [ 0, -1 ].each do |capacity|
      concert = Concert.new(concert_attributes(capacity: capacity))
      assert_not concert.valid?, "capacity #{capacity} should be invalid"
      assert_includes concert.errors.attribute_names, :capacity
    end
  end

  test "rejects a non positive capacity in the database" do
    assert_raises ActiveRecord::StatementInvalid do
      Concert.insert!(concert_insert_attributes(capacity: 0))
    end
  end

  test "requires the end to be after the start" do
    starts_at = 1.week.from_now

    [ starts_at, starts_at - 1.hour ].each do |ends_at|
      concert = Concert.new(concert_attributes(starts_at: starts_at, ends_at: ends_at))
      assert_not concert.valid?
      assert_includes concert.errors.attribute_names, :ends_at
    end
  end

  test "rejects an invalid time range in the database" do
    starts_at = 1.week.from_now.change(usec: 0)

    assert_raises ActiveRecord::StatementInvalid do
      Concert.insert!(concert_insert_attributes(starts_at: starts_at, ends_at: starts_at - 1.hour))
    end
  end

  test "requires description and setlist from publication onwards" do
    concert = Concert.create!(concert_attributes)

    concert.status = :published
    assert_not concert.valid?
    assert_includes concert.errors.attribute_names, :description
    assert_includes concert.errors.attribute_names, :setlist

    concert.description = "Ein Abend mit Klaviermusik."
    concert.setlist = "Nocturne op. 9 Nr. 2\nBallade Nr. 1"
    assert concert.valid?
  end

  test "keeps description and setlist required for a cancelled concert" do
    concert = Concert.create!(concert_attributes(
      status: :published,
      description: "Ein Abend mit Klaviermusik.",
      setlist: "Nocturne op. 9 Nr. 2"
    ))

    concert.update(status: :cancelled, description: "", setlist: "")

    assert_not concert.valid?
    assert_includes concert.errors.attribute_names, :description
    assert_includes concert.errors.attribute_names, :setlist
  end

  test "supports all three statuses and defaults to draft" do
    assert_equal %w[draft published cancelled], Concert.statuses.keys
    assert_equal "draft", Concert.new.status
  end

  test "rejects an unsupported status" do
    concert = Concert.new(concert_attributes(status: "postponed"))
    assert_not concert.valid?
    assert_includes concert.errors.attribute_names, :status
  end

  test "rejects an unsupported status in the database" do
    assert_raises ActiveRecord::StatementInvalid do
      Concert.insert!(concert_insert_attributes(status: "postponed"))
    end
  end

  test "playlist_url is optional" do
    assert Concert.new(concert_attributes(playlist_url: nil)).valid?
    assert Concert.new(concert_attributes(playlist_url: "https://example.com/playlist")).valid?
  end

  test "rejects a playlist_url that is not an http address" do
    [ "javascript:alert(1)", "example.com/playlist", "https://example.com\njavascript:alert(1)" ].each do |url|
      concert = Concert.new(concert_attributes(playlist_url: url))

      assert_not concert.valid?, "#{url} should be invalid"
      assert_includes concert.errors.attribute_names, :playlist_url
    end
  end

  test "reads the setlist as one song per line" do
    concert = Concert.new(concert_attributes(setlist: "Erster Song\n\n  Zweiter Song  \n"))

    assert_equal [ "Erster Song", "Zweiter Song" ], concert.setlist_lines
    assert_equal [], Concert.new(concert_attributes).setlist_lines
  end

  test "calculates free seats from capacity minus registrations" do
    concert = Concert.create!(concert_attributes(capacity: 2))
    assert_equal 2, concert.free_seats
    assert_not concert.full?

    Registration.create!(user: users(:one), concert: concert)
    assert_equal 1, concert.free_seats

    Registration.create!(user: users(:two), concert: concert)
    assert_equal 0, concert.free_seats
    assert concert.full?
  end

  test "knows whether it has started" do
    assert_not Concert.new(concert_attributes).started?

    started = Concert.new(concert_attributes(starts_at: 1.hour.ago, ends_at: 1.hour.from_now))
    assert started.started?
  end

  test "uses optimistic locking" do
    concert = Concert.create!(concert_attributes)
    assert_equal 0, concert.lock_version

    stale = Concert.find(concert.id)
    concert.update!(title: "Neuer Titel")

    stale.title = "Konkurrierender Titel"
    assert_raises(ActiveRecord::StaleObjectError) { stale.save! }
  end

  test "does not delete registrations together with the concert" do
    concert = Concert.create!(concert_attributes)
    Registration.create!(user: users(:one), concert: concert)

    assert_not concert.destroy
    assert Concert.exists?(concert.id)
  end

  test "registers a user for a published concert" do
    concert = Concert.create!(published_concert_attributes)

    registration = concert.register(users(:one))

    assert registration.persisted?
    assert_equal users(:one), registration.user
    assert_equal 1, concert.reload.registrations.count
  end

  test "rejects a second registration of the same user" do
    concert = Concert.create!(published_concert_attributes)
    concert.register(users(:one))

    duplicate = concert.register(users(:one))

    assert_not duplicate.persisted?
    assert_equal [ I18n.t("activerecord.errors.models.registration.attributes.base.duplicate") ],
                 duplicate.errors.full_messages
    assert_equal 1, concert.reload.registrations.count
  end

  test "rejects a registration for a full concert" do
    concert = Concert.create!(published_concert_attributes(capacity: 1))
    concert.register(users(:one))

    registration = concert.register(users(:two))

    assert_not registration.persisted?
    assert_equal [ I18n.t("activerecord.errors.models.registration.attributes.base.full") ],
                 registration.errors.full_messages
  end

  test "rejects a registration for a draft, a cancelled and a started concert" do
    closed = [
      Concert.create!(concert_attributes),
      Concert.create!(published_concert_attributes(status: :cancelled)),
      Concert.create!(published_concert_attributes(starts_at: 1.hour.ago, ends_at: 1.hour.from_now))
    ]

    closed.each do |concert|
      registration = concert.register(users(:one))

      assert_not registration.persisted?, "#{concert.status} concert accepted a registration"
      assert_equal [ I18n.t("activerecord.errors.models.registration.attributes.base.closed") ],
                   registration.errors.full_messages
    end
  end

  test "frees the seat again after a cancellation and allows a new registration" do
    concert = Concert.create!(published_concert_attributes(capacity: 1))
    registration = concert.register(users(:one))

    assert registration.withdraw
    assert_equal 1, concert.reload.free_seats

    assert concert.register(users(:two)).persisted?
  end

  test "publishes a draft" do
    concert = Concert.create!(concert_attributes(description: "Beschreibung", setlist: "Song"))

    assert concert.publish
    assert concert.reload.published?
  end

  test "rejects publishing without a description or a setlist" do
    concert = Concert.create!(concert_attributes)

    assert_not concert.publish
    assert concert.reload.draft?
    assert_includes concert.errors.attribute_names, :description
    assert_includes concert.errors.attribute_names, :setlist
  end

  test "rejects publishing a concert that is not an upcoming draft" do
    published = Concert.create!(published_concert_attributes)
    started = Concert.create!(concert_attributes(description: "B", setlist: "S",
                                                 starts_at: 1.hour.ago, ends_at: 1.hour.from_now))

    [ published, started ].each do |concert|
      assert_not concert.publish
      assert_includes concert.errors.full_messages,
                      I18n.t("activerecord.errors.models.concert.attributes.base.not_publishable")
    end
  end

  test "cancels a published concert and keeps its registrations" do
    concert = Concert.create!(published_concert_attributes)
    concert.register(users(:one))

    assert concert.cancel
    assert concert.reload.cancelled?
    assert_equal 1, concert.registrations.count
  end

  test "rejects cancelling a draft or a started concert" do
    draft = Concert.create!(concert_attributes)
    started = Concert.create!(published_concert_attributes(starts_at: 1.hour.ago, ends_at: 1.hour.from_now))

    [ draft, started ].each do |concert|
      assert_not concert.cancel
      assert_includes concert.errors.full_messages,
                      I18n.t("activerecord.errors.models.concert.attributes.base.not_cancellable")
    end
  end

  test "rejects a capacity below the current occupancy" do
    concert = Concert.create!(published_concert_attributes(capacity: 2))
    concert.register(users(:one))
    concert.register(users(:two))

    assert_not concert.apply_changes(capacity: 1)
    assert_includes concert.errors.attribute_names, :capacity
    assert_equal 2, concert.reload.capacity
  end

  test "accepts a capacity equal to the current occupancy" do
    concert = Concert.create!(published_concert_attributes(capacity: 2))
    concert.register(users(:one))

    assert concert.apply_changes(capacity: 1)
    assert_equal 1, concert.reload.capacity
  end

  test "rejects a change based on a stale version" do
    concert = Concert.create!(concert_attributes)
    stale = Concert.find(concert.id)
    concert.apply_changes(title: "Neuer Titel")

    assert_raises(ActiveRecord::StaleObjectError) { stale.apply_changes(title: "Konkurrierender Titel") }
    assert_equal "Neuer Titel", concert.reload.title
  end

  private
    # Attributes for insert!, which bypasses the model and therefore needs raw column values.
    def concert_insert_attributes(**attributes)
      starts_at = 1.week.from_now.change(usec: 0)

      {
        creator_id: users(:organizer).id,
        title: "Testkonzert",
        capacity: 2,
        status: "draft",
        starts_at: starts_at,
        ends_at: starts_at + 2.hours
      }.merge(attributes)
    end
end
