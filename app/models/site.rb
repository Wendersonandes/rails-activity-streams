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
    return site if site

    site = create!(name: "Plataforma")
    site.build_actor(name: site.name)
    site.save!
    site
  end

  delegate :slug, to: :actor, allow_nil: true
end
