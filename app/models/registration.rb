class Registration < ApplicationRecord
  belongs_to :user
  belongs_to :concert

  validates :user_id, uniqueness: { scope: :concert_id }
end
