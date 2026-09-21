# Role and lifecycle rules for concerts. Both are fixed in docs/spec/PROJECT.md, so they live
# together here instead of being re-checked at every call site.
#
# What deliberately stays out: free seats, duplicate registrations and the description/setlist
# requirement for publishing. A policy runs outside the transaction, so it cannot be the boundary
# for anything that has to be read inside one.
class ConcertPolicy < ApplicationPolicy
  # Organizers and admins see every concert, drafts included. Everyone else sees upcoming
  # concerts that are published or cancelled — a cancelled concert stays listed because it
  # remains history its participants need to find.
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user.organizer? || user.admin?

      scope.where.not(status: :draft).where.not(starts_at: ..Time.current)
    end
  end

  def index?
    true
  end

  # Past concerts drop out of the listing but stay readable for the participants who registered,
  # so their own registrations never point at a page they may not open.
  def show?
    return true if manages_concerts?

    !record.draft? && (!record.started? || registered?)
  end

  def create?
    manages_concerts?
  end

  def update?
    manages_concerts? && !record.started?
  end

  def destroy?
    manages_concerts? && record.draft?
  end

  def publish?
    manages_concerts? && record.draft? && !record.started?
  end

  def cancel?
    manages_concerts? && record.published? && !record.started?
  end

  def participants?
    manages_concerts?
  end

  private
    # creator_id records who created a concert and never restricts who may manage it — see the
    # naming table in docs/spec/PROJECT.md.
    def manages_concerts?
      user.organizer? || user.admin?
    end

    def registered?
      record.registrations.exists?(user: user)
    end
end
