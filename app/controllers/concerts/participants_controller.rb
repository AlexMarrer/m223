# S11, the participant list of one concert. Organizers and admins only.
class Concerts::ParticipantsController < Concerts::BaseController
  def index
    authorize @concert, :participants?

    @registrations = @concert.registrations.includes(:user).order(:created_at)
  end
end
