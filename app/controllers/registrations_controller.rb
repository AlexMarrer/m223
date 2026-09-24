class RegistrationsController < ApplicationController
  before_action :set_concert, only: %i[ create destroy ]

  # S05. Reading the association is what limits the list to the signed-in user; a user can hold
  # registrations for concerts that have already started, which the concert scope filters out.
  def index
    authorize Registration

    @registrations = Current.user.registrations.includes(:concert).order(created_at: :desc)
  end

  def create
    authorize Registration.new(concert: @concert, user: Current.user)

    registration = @concert.register(Current.user)

    if registration.persisted?
      redirect_to @concert, notice: t(".created", title: @concert.title)
    else
      redirect_to @concert, alert: registration.errors.full_messages.to_sentence
    end
  end

  def destroy
    registration = Current.user.registrations.find_by!(concert: @concert)
    authorize registration

    if registration.withdraw
      redirect_to @concert, notice: t(".destroyed", title: @concert.title)
    else
      redirect_to @concert, alert: registration.errors.full_messages.to_sentence
    end
  end

  private
    def set_concert
      @concert = Concert.find(params[:concert_id])
    end

    # RegistrationPolicy refuses a concert that is cancelled or has started. Both are public
    # knowledge, so the visitor learns the reason. A draft keeps the generic denial, which does
    # not reveal that it exists.
    def deny_access
      return super if @concert.nil? || @concert.draft?

      reason = @concert.cancelled? ? :cancelled : :started
      target = policy(@concert).show? ? @concert : root_url
      redirect_to target, alert: t("registrations.closed.#{reason}")
    end
end
