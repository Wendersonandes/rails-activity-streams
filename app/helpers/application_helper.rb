module ApplicationHelper
  include Pagy::Frontend

  def activity_description(activity)
    I18n.t("activity.description.#{activity.verb}",
      author: activity.author.name,
      owner: activity.owner.name,
      default: nil
    )
  end
end
