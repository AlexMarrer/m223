class User < ApplicationRecord
  MINIMUM_PASSWORD_LENGTH = 12

  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :created_concerts, class_name: "Concert", foreign_key: :creator_id, inverse_of: :creator
  has_many :registrations
  has_many :concerts, through: :registrations
  has_many :activities, foreign_key: :actor_id, inverse_of: :actor

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :unconfirmed_email, with: ->(e) { e.strip.downcase }

  enum :role, { user: "user", organizer: "organizer", admin: "admin" }, default: "user", validate: true

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true
  validates :password, length: { minimum: MINIMUM_PASSWORD_LENGTH }, allow_nil: true
end
