class Registration < ApplicationRecord
  belongs_to :user
  belongs_to :concert

  validates :user_id, uniqueness: { scope: :concert_id }

  # The Storno of one registration, as opposed to the Absage of a whole concert. Runs in the same
  # protected transaction as a booking, so the freed seat is visible to whoever is waiting for it. A cancelled concert keeps its registrations, which is
  # why the status is re-read here rather than trusted from the request.
  def withdraw
    concert.transaction do
      Concert.uncached do
        concert.reload

        if concert.open_for_registration?
          destroy
        else
          errors.add(:base, :closed)
          false
        end
      end
    end
  end
end
