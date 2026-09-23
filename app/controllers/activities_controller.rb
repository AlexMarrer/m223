# S14, the activity feed. It has no per-record screen, so the class is what gets authorized —
# see ActivityPolicy.
class ActivitiesController < ApplicationController
  def index
    authorize Activity

    @activities = Activity.includes(:actor, :concert).order(created_at: :desc)
  end
end
