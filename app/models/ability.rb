class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user.admin?
      can :manage, :all
    elsif user.persisted?
      can :read, Recipe
      can :create, Recipe
      can [:update, :destroy], Recipe, user_id: user.id
    else
      can :read, Recipe
    end
  end
end
