# The activity feed is a management view. It has no per-record screen, so it is authorized
# against the Activity class.
class ActivityPolicy < ApplicationPolicy
  def index?
    user.organizer? || user.admin?
  end
end
