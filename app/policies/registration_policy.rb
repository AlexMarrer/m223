# Who may register and cancel. Whether a seat is actually free is not decided here: the policy
# runs before the transaction, so the occupancy check belongs to the registration use case.
#
# The record is a Registration carrying the concert — for create? an unsaved one.
class RegistrationPolicy < ApplicationPolicy
  # Everyone may open their own list. Which registrations are in it is not a policy question:
  # RegistrationsController reads them from Current.user.
  def index?
    true
  end

  # No role restriction: organizers and admins take part like everyone else.
  def create?
    open_for_registration?
  end

  # Only the participant themselves, never an organizer or admin on their behalf.
  def destroy?
    record.user == user && open_for_registration?
  end

  private
    def open_for_registration?
      concert.published? && !concert.started?
    end

    def concert
      record.concert
    end
end
