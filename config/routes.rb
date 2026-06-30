Rails.application.routes.draw do
  devise_for :users
  # Reveal health status on /up
  get "up" => "rails/health#show", as: :rails_health_check

  # Root
  root to: redirect("/up")
end
