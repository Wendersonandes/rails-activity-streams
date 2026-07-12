module MentionsHelper
  # Renders the text by replacing mention tags with actual link elements.
  # Preloaded mentions are used to avoid N+1 database queries.
  #
  # @param activity_object [ActivityObject] the backing activity object containing text
  # @return [ActiveSupport::SafeBuffer] the HTML safe string with mention links
  def render_with_mentions(activity_object)
    return "" if activity_object.nil?

    mentions = activity_object.mentions

    return "" if activity_object.description.blank?

    text = ERB::Util.html_escape(activity_object.description)

    return text if mentions.empty?

    # Map slugs to actors using preloaded association to avoid N+1 queries
    mentions_by_slug = mentions.each_with_object({}) do |mention, hash|
      hash[mention.actor.slug] = mention.actor
    end

    text.gsub(MentionManager::MENTION_REGEX) do |match|
      name = $1
      slug = $2
      actor = mentions_by_slug[slug]

      if actor
        # Use helper method public_path_for if defined (controller context), fallback otherwise
        path = respond_to?(:public_path_for) ? public_path_for(actor) : default_public_path_for(actor)
        link_to(name, path, class: "text-blue-600 hover:text-blue-700 hover:underline font-semibold", data: { turbo: false })
      else
        match
      end
    end.html_safe
  end

  # Formats the text for use inside the contenteditable editor, replacing mentions with spans.
  def render_editor_mentions(activity_object)
    return "" if activity_object.nil? || activity_object.description.blank?

    text = ERB::Util.html_escape(activity_object.description)
    mentions = activity_object.mentions.includes(:actor)

    return text if mentions.empty?

    mentions_by_slug = mentions.each_with_object({}) do |mention, hash|
      hash[mention.actor.slug] = mention.actor
    end

    text.gsub(MentionManager::MENTION_REGEX) do |match|
      name = $1
      slug = $2
      actor = mentions_by_slug[slug]

      if actor
        "<span class=\"mention-pill bg-blue-50 text-blue-700 px-1.5 py-0.5 rounded-md font-medium text-xs inline-block mx-0.5\" data-slug=\"#{slug}\" contenteditable=\"false\">@#{name}</span>"
      else
        match
      end
    end.html_safe
  end

  private

  def default_public_path_for(actor)
    url_helpers = Rails.application.routes.url_helpers
    case actor.actorable_type
    when "Profile"
      url_helpers.profile_path(actor)
    when "Group"
      url_helpers.group_path(actor.actorable_id)
    else
      url_helpers.actor_path(actor)
    end
  end
end
