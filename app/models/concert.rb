class Concert < ApplicationRecord
  belongs_to :creator, class_name: "User"

  # Registrations and activities are history and are never deleted with the concert. Only drafts
  # are deletable, and a draft cannot have either, so this never fires in normal operation.
  has_many :registrations, dependent: :restrict_with_error
  has_many :participants, through: :registrations, source: :user
  has_many :activities, dependent: :restrict_with_error

  enum :status, { draft: "draft", published: "published", cancelled: "cancelled" },
       default: "draft", validate: true

  validates :title, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }
  validates :starts_at, :ends_at, presence: true
  validates :description, :setlist, presence: true, unless: :draft?
  # The detail page turns this into a real link, so anything but a single http(s) address is
  # rejected — anchored at both ends, or a valid prefix could carry a javascript: payload behind
  # a line break.
  validates :playlist_url, format: { with: %r{\Ahttps?://\S+\z}i }, allow_blank: true
  validate :ends_at_after_starts_at
  validate :capacity_not_below_occupancy, if: -> { persisted? && capacity_changed? }

  def free_seats
    capacity - registrations.count
  end

  def full?
    free_seats <= 0
  end

  def started?
    starts_at.present? && starts_at <= Time.current
  end

  def open_for_registration?
    published? && !started?
  end

  # The setlist is stored as text with one song per line, in the planned order.
  def setlist_lines
    setlist.to_s.lines.map(&:strip).reject(&:empty?)
  end

  # Books a seat and returns the registration: persisted on success, carrying German messages
  # otherwise. Status and occupancy are read inside the transaction, which SQLite opens as
  # BEGIN IMMEDIATE — two parallel bookings therefore serialize instead of both seeing the same
  # free seat. See docs/datenmodell.md, section 6.
  def register(user)
    registration = Registration.new(concert: self, user: user)

    begin
      protected_by_transaction do
        if !open_for_registration?
          registration.errors.add(:base, :closed)
        elsif registrations.exists?(user: user)
          registration.errors.add(:base, :duplicate)
        elsif full?
          registration.errors.add(:base, :full)
        else
          registration.save
        end
      end
    rescue ActiveRecord::RecordNotUnique
      # The unique index is the last instance, for a duplicate that slipped past the check above
      # between two parallel requests. The transaction is already rolled back here.
      registration.errors.add(:base, :duplicate)
    end

    registration
  end

  # Rejected when the concert is no longer a draft, has started, or still lacks the description
  # or setlist that every published concert needs.
  def publish
    protected_by_transaction do
      if draft? && !started?
        update(status: :published)
      else
        errors.add(:base, :not_publishable)
        false
      end
    end
  end

  # Calls the concert off, which is the Absage and never the Storno of a single registration.
  # The registrations are kept: they are the history of who had signed up.
  def cancel
    protected_by_transaction do
      if published? && !started?
        update(status: :cancelled)
      else
        errors.add(:base, :not_cancellable)
        false
      end
    end
  end

  # The capacity check runs as a validation inside this transaction, so a reduction cannot
  # decide against an occupancy that a parallel booking is about to change. The record
  # itself is guarded by lock_version, which raises ActiveRecord::StaleObjectError.
  #
  # Unlike the other operations this one must not reload: the caller's lock_version comes from
  # the submitted form and is exactly what the stale check compares against.
  def apply_changes(attributes)
    transaction { self.class.uncached { update(attributes) } }
  end

  private
    # The protected path from docs/datenmodell.md, section 6. SQLite opens the transaction with
    # BEGIN IMMEDIATE, so concurrent writers serialize and the state read here is the state the
    # write is based on.
    #
    # The block runs uncached on purpose: a connection keeps the query cache of whoever checked
    # it out first, so an occupancy count cached before a parallel booking committed could
    # otherwise be served here — and a stale count is exactly what this path must not act on.
    def protected_by_transaction
      transaction do
        self.class.uncached do
          reload
          yield
        end
      end
    end

    def ends_at_after_starts_at
      return if starts_at.blank? || ends_at.blank?

      errors.add(:ends_at, :after_starts_at) if ends_at <= starts_at
    end

    def capacity_not_below_occupancy
      occupancy = registrations.count

      errors.add(:capacity, :below_occupancy, count: occupancy) if capacity.to_i < occupancy
    end
end
