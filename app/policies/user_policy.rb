# Covers the admin user management and the self-service account screens. Both act on a User but
# mean different things, so neither reuses the other's query names.
class UserPolicy < ApplicationPolicy
  def manage?
    user.admin?
  end

  alias_method :index?, :manage?
  alias_method :edit?, :manage?
  alias_method :update?, :manage?

  # Admin::UsersController enforces this through its permitted parameters. The rule is stated
  # here so the role model has one authoritative home.
  def change_role?
    user.admin? && record != user
  end

  # True by construction wherever it is called today, because the account screens always work on
  # Current.user. It is worth the call anyway: it satisfies verify_authorized and fails closed if
  # one of those controllers ever starts looking a user up by id.
  def own_account?
    record == user
  end
end
