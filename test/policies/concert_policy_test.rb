require "test_helper"

class ConcertPolicyTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @organizer = users(:organizer)
    @admin = users(:admin)
  end

  # Unsaved records are enough for every query but the scope, which needs rows to filter.
  # Anything past draft has to carry a description and a setlist to survive validation.
  def concert(status: :published, starts_at: 1.week.from_now, persisted: false)
    attributes = concert_attributes(status: status, starts_at: starts_at, ends_at: starts_at + 2.hours)
    attributes.merge!(description: "Beschreibung", setlist: "Lied eins") unless status == :draft

    persisted ? Concert.create!(attributes) : Concert.new(attributes)
  end

  test "everyone may open the listing" do
    [ @user, @organizer, @admin ].each do |actor|
      assert ConcertPolicy.new(actor, Concert).index?
    end
  end

  test "a participant sees upcoming published and cancelled concerts" do
    assert ConcertPolicy.new(@user, concert).show?
    assert ConcertPolicy.new(@user, concert(status: :cancelled)).show?
  end

  test "a participant never sees a draft" do
    assert_not ConcertPolicy.new(@user, concert(status: :draft)).show?
  end

  test "organizers and admins see drafts" do
    draft = concert(status: :draft)

    assert ConcertPolicy.new(@organizer, draft).show?
    assert ConcertPolicy.new(@admin, draft).show?
  end

  test "a started concert stays readable for a participant who registered for it" do
    started = concert(starts_at: 1.day.ago, persisted: true)
    Registration.create!(user: @user, concert: started)

    assert ConcertPolicy.new(@user, started).show?
  end

  test "a started concert is closed to a participant without a registration" do
    started = concert(starts_at: 1.day.ago, persisted: true)

    assert_not ConcertPolicy.new(@user, started).show?
  end

  test "only organizers and admins create concerts" do
    assert ConcertPolicy.new(@organizer, Concert).create?
    assert ConcertPolicy.new(@admin, Concert).create?
    assert_not ConcertPolicy.new(@user, Concert).create?
  end

  test "a participant manages no concert" do
    upcoming = concert

    %i[ update? destroy? publish? cancel? participants? ].each do |query|
      assert_not ConcertPolicy.new(@user, upcoming).public_send(query), "user should not be allowed to #{query}"
    end
  end

  test "an organizer manages a concert they did not create" do
    foreign = Concert.new(concert_attributes(creator: @admin))

    assert ConcertPolicy.new(@organizer, foreign).update?
    assert ConcertPolicy.new(@organizer, foreign).destroy?
  end

  test "only drafts may be deleted" do
    assert ConcertPolicy.new(@organizer, concert(status: :draft)).destroy?
    assert_not ConcertPolicy.new(@organizer, concert).destroy?
    assert_not ConcertPolicy.new(@organizer, concert(status: :cancelled)).destroy?
  end

  test "publishing applies to drafts, cancelling to published concerts" do
    draft = concert(status: :draft)
    published = concert

    assert ConcertPolicy.new(@organizer, draft).publish?
    assert_not ConcertPolicy.new(@organizer, published).publish?

    assert ConcertPolicy.new(@organizer, published).cancel?
    assert_not ConcertPolicy.new(@organizer, draft).cancel?
  end

  test "a cancelled concert is history and no longer editable" do
    assert_not ConcertPolicy.new(@organizer, concert(status: :cancelled)).update?
    assert_not ConcertPolicy.new(@admin, concert(status: :cancelled)).update?
    assert ConcertPolicy.new(@organizer, concert).update?
    assert ConcertPolicy.new(@organizer, concert(status: :draft)).update?
  end

  test "a started concert can no longer be edited, published or cancelled" do
    started = concert(starts_at: 1.hour.ago)
    started_draft = concert(status: :draft, starts_at: 1.hour.ago)

    assert_not ConcertPolicy.new(@organizer, started).update?
    assert_not ConcertPolicy.new(@organizer, started).cancel?
    assert_not ConcertPolicy.new(@organizer, started_draft).publish?
  end

  test "only organizers and admins reach the participant list" do
    upcoming = concert

    assert ConcertPolicy.new(@organizer, upcoming).participants?
    assert ConcertPolicy.new(@admin, upcoming).participants?
    assert_not ConcertPolicy.new(@user, upcoming).participants?
  end

  test "the scope gives a participant upcoming published and cancelled concerts" do
    upcoming = concert(persisted: true)
    cancelled = concert(status: :cancelled, persisted: true)
    concert(status: :draft, persisted: true)
    concert(starts_at: 1.day.ago, persisted: true)

    resolved = ConcertPolicy::Scope.new(@user, Concert).resolve

    assert_equal [ cancelled, upcoming ].sort, resolved.sort
  end

  test "the scope gives organizers and admins every concert" do
    concert(persisted: true)
    concert(status: :draft, persisted: true)
    concert(starts_at: 1.day.ago, persisted: true)

    assert_equal Concert.count, ConcertPolicy::Scope.new(@organizer, Concert).resolve.count
    assert_equal Concert.count, ConcertPolicy::Scope.new(@admin, Concert).resolve.count
  end
end
