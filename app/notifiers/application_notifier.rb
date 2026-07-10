# Base notifier class for Noticed. All notifier classes should inherit from this.
class ApplicationNotifier < Noticed::Event
  validate :activity_exists

  private

  def activity_exists
    if params[:activity].nil?
      errors.add(:base, "Associated activity no longer exists")
    end
  end
end
