# Base for every policy. Nothing is permitted unless a subclass says so.
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "must be signed in" unless user

    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      raise Pundit::NotAuthorizedError, "must be signed in" unless user

      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "#{self.class} must define #resolve"
    end
  end
end
