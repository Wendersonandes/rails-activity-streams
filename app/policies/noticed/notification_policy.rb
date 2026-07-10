module Noticed
  class NotificationPolicy < ApplicationPolicy
    def index?
      actor.present?
    end

    def update?
      actor.present? && record.recipient == actor
    end

    def mark_all_as_read?
      actor.present?
    end

    class Scope < Scope
      def resolve
        if actor
          scope.where(recipient: actor)
        else
          scope.none
        end
      end
    end
  end
end
