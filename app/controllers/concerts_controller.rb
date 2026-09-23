class ConcertsController < ApplicationController
  before_action :set_concert, only: %i[ show edit update destroy ]

  # S03 for participants and S09 for organizers and admins are the same screen: the scope decides
  # which concerts are in it, the view decides which controls are rendered.
  def index
    authorize Concert

    @concerts = policy_scope(Concert).order(:starts_at)

    # One grouped count for the whole listing; Concert#free_seats would query per row.
    occupancy = Registration.where(concert: @concerts).group(:concert_id).count
    @free_seats = @concerts.index_with { |concert| concert.capacity - occupancy.fetch(concert.id, 0) }
  end

  # The registration is either the visitor's own one or an unsaved stand-in, so the view can ask
  # the policy whether registering or withdrawing is offered.
  def show
    @registration = Current.user.registrations.find_by(concert: @concert) ||
                    Registration.new(concert: @concert, user: Current.user)
  end

  def new
    @concert = Concert.new
    authorize @concert
  end

  def create
    @concert = Concert.new(concert_params.merge(creator: Current.user))
    authorize @concert

    if @concert.save
      redirect_to @concert, notice: t(".created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @concert.apply_changes(concert_params, actor: Current.user)
      redirect_to @concert, notice: t(".updated")
    else
      render :edit, status: :unprocessable_content
    end
  rescue ActiveRecord::StaleObjectError
    # Someone else saved in the meantime. The form keeps what was entered here and offers to
    # reload the current state; nothing of the newer version is overwritten.
    @stale = true
    render :edit, status: :conflict
  end

  def destroy
    if @concert.destroy
      redirect_to concerts_path, notice: t(".destroyed")
    else
      redirect_to @concert, alert: t(".not_destroyed")
    end
  end

  private
    def set_concert
      @concert = Concert.find(params[:id])
      authorize @concert
    end

    # The status is not assignable: it moves through publishing and cancelling, which are their
    # own resources. lock_version has to be permitted, or every save would look current.
    def concert_params
      params.expect(concert: [ :title, :description, :setlist, :playlist_url, :capacity,
                               :starts_at, :ends_at, :lock_version ])
    end
end
