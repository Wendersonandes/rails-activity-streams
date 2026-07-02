Rails.application.routes.draw do
  devise_for :users

  # Core social — perfil e grupos
  resources :actors, only: [ :index, :show ]
  resource :profile, only: [ :show, :edit, :update ], controller: "profiles"
  resources :groups do
    resources :memberships, only: [ :index, :create, :update, :destroy ], controller: "group_memberships" do
      collection do
        get  :insights
        post :approve_request
        post :reject_request
        post :accept_invite
        post :decline_invite
      end
    end
  end

  # Activity stream — feed
  resources :activities, only: [ :index, :show, :new, :create, :destroy ] do
    resources :activity_actions, only: [ :create, :destroy ]
  end

  # Contacts — gerenciamento de conexoes
  resources :contacts, only: [ :index, :create, :destroy ]

  # Account — configuracoes do usuario (singular route -> UsersController)
  resource :account, controller: "users", only: [ :show, :edit, :update ]

  # Admin namespace
  namespace :admin do
    resources :permissions, only: [ :index ]
    resources :ties, only: [ :index, :show ]
    resources :audiences, only: [ :index ]
    resources :roles, only: [ :index, :create, :update ]
  end

  # Locations — dynamic state/city loading
  get "locations/states", to: "locations#states"
  get "locations/cities", to: "locations#cities"

  # Health + Root
  get "up" => "rails/health#show", as: :rails_health_check
  root to: "activities#index"
end
