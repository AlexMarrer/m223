# Calls a concert off. The registrations stay as history, which is why this is not a deletion.
class Concerts::CancellationsController < Concerts::BaseController
  def create
    authorize @concert, :cancel?

    if @concert.cancel(Current.user)
      redirect_to @concert, notice: t(".cancelled")
    else
      redirect_to @concert, alert: @concert.errors.full_messages.to_sentence
    end
  end
end
