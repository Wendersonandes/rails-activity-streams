# == Schema Information
#
# Table name: relations
#
#  id            :bigint           not null, primary key
#  name          :string           not null
#  receiver_type :string
#  sender_type   :string
#  type          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  actor_id      :bigint
#  parent_id     :bigint
#
# Indexes
#
#  index_relations_on_actor_id   (actor_id)
#  index_relations_on_parent_id  (parent_id)
#
# Foreign Keys
#
#  fk_rails_...  (actor_id => actors.id) ON DELETE => restrict
#  fk_rails_...  (parent_id => relations.id) ON DELETE => nullify
#
class Relation::Single < Relation
  PERMISSIONS = [].freeze

  class << self
    def instance
      @instance ||= first || create!(
        name: name.demodulize.underscore,
        permissions: permissions
      )
    end

    def permissions
      with_object = self::PERMISSIONS.select { |_, obj| obj.present? }
      without_object = self::PERMISSIONS.select { |_, obj| obj.blank? }

      scope = Permission.none
      scope = scope.or(Permission.where(action: with_object.map(&:first), object: with_object.map(&:second))) if with_object.any?
      scope = scope.or(Permission.where(action: without_object.map(&:first), object: nil)) if without_object.any?
      scope
    end

    def create_activity?
      true
    end
  end

  def name
    I18n.t("relation.#{self.class.name.demodulize.underscore}.name")
  end

  def available_permissions
    self.class.permissions
  end
end
