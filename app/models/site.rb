# == Schema Information
#
# Table name: sites
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# The {Site} is the application itself represented as an {Actor}. It is the third concrete
# type behind +delegated_type :actorable+ ({Profile}, {Group}, {Site}) and acts as the global
# entity that owns site-wide relations such as {Relation::LocalAdmin}.
#
# A single site record is expected; reach it through {.instance}.
#
# @see Actor
# @see Relation::LocalAdmin
class Site < ApplicationRecord
  has_one :actor, as: :actorable, dependent: :destroy, autosave: true

  validates :name, presence: true

  # The singleton site record, creating it (and its backing {Actor}) on first access.
  #
  # @return [Site]
  def self.instance
    site = find_by(name: "Plataforma")
    return site if site && site.actor.present?

    unless site
      site = create!(name: "Plataforma")
    end

    site.build_actor(name: site.name) unless site.actor
    site.save! if site.actor.new_record?
    site
  end

  delegate :slug, to: :actor, allow_nil: true
end
