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
  validate :ends_at_after_starts_at

  def free_seats
    capacity - registrations.count
  end

  def full?
    free_seats <= 0
  end

  def started?
    starts_at.present? && starts_at <= Time.current
  end

  private
    def ends_at_after_starts_at
      return if starts_at.blank? || ends_at.blank?

      errors.add(:ends_at, :after_starts_at) if ends_at <= starts_at
    end
end
