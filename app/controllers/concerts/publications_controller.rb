# Publishes a concert. Its own resource, because it is a state change and not an edit.
class Concerts::PublicationsController < Concerts::BaseController
  def create
    authorize @concert, :publish?

    if @concert.publish(Current.user)
      redirect_to @concert, notice: t(".published")
    else
      # A draft may be saved without a description and a setlist, but not published without
      # them. S10 is where those fields are, so the rejection is shown there.
      render template: "concerts/edit", status: :unprocessable_content
    end
  end
end
