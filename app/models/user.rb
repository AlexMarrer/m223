class User < ApplicationRecord
  MINIMUM_PASSWORD_LENGTH = 12
  EMAIL_CONFIRMATION_EXPIRY = 24.hours

  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :created_concerts, class_name: "Concert", foreign_key: :creator_id, inverse_of: :creator
  has_many :registrations
  has_many :concerts, through: :registrations
  has_many :activities, foreign_key: :actor_id, inverse_of: :actor

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :unconfirmed_email, with: ->(e) { e.strip.downcase }

  enum :role, { user: "user", organizer: "organizer", admin: "admin" }, default: "user", validate: true

  # The pending address is the token payload: confirming the change, or requesting a newer one,
  # invalidates every link handed out earlier.
  generates_token_for :email_confirmation, expires_in: EMAIL_CONFIRMATION_EXPIRY do
    unconfirmed_email
  end

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true
  validates :password, length: { minimum: MINIMUM_PASSWORD_LENGTH }, allow_nil: true
  # Only the email-change form requires an address. Every other save has to leave a pending
  # change untouched, so this check cannot be unconditional.
  validates :unconfirmed_email, presence: true, on: :email_change
  validate :unconfirmed_email_available

  # Moves the pending address into email_address. Returns false when there is nothing to confirm
  # or when the address was taken in the meantime; the pending change then survives.
  def confirm_email
    return false if unconfirmed_email.blank?

    self.email_address = unconfirmed_email
    self.unconfirmed_email = nil

    save.tap { |confirmed| restore_pending_email unless confirmed }
  end

  private
    def unconfirmed_email_available
      return if unconfirmed_email.blank?

      if unconfirmed_email == email_address
        errors.add(:unconfirmed_email, :unchanged)
      elsif User.where.not(id: id).exists?(email_address: unconfirmed_email)
        errors.add(:unconfirmed_email, :taken)
      end
    end

    # Undoes the assignment above, so a caller still sees the pending change after a failed save.
    def restore_pending_email
      self.unconfirmed_email = email_address
      restore_attributes([ :email_address ])
    end
end
