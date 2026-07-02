# == Schema Information
#
# Table name: sites
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Site < ApplicationRecord
  has_one :actor, as: :actorable, dependent: :destroy, autosave: true

  validates :name, presence: true

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
