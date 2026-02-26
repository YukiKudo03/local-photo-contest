Rails.application.routes.draw do
  # Locale switching
  patch "locale", to: "locales#update", as: :locale

  # Health check endpoints
  get "health", to: "health#show"
  get "health/details", to: "health#details"

  # Devise routes for user authentication
  devise_for :users, path: "organizers", controllers: {
    sessions: "organizers/sessions",
    registrations: "organizers/registrations",
    passwords: "organizers/passwords",
    confirmations: "organizers/confirmations"
  }

  # Gallery
  resources :gallery, only: [ :index ] do
    collection do
      get :map
      get :map_data
    end
  end

  # Help pages (public access, no authentication required)
  get "help", to: "help#index", as: :help
  get "help/:guide", to: "help#show", as: :help_guide,
      constraints: { guide: /participant|organizer|judge|admin/ }

  # Participant-facing routes
  resources :contests, only: [ :index, :show ] do
    resources :entries, only: [ :new, :create ], shallow: true
    resource :results, only: [ :show ], controller: "contests/results"
  end
  resources :entries, only: [ :show, :edit, :update, :destroy ] do
    resource :vote, only: [ :create, :destroy ]
    resources :comments, only: [ :create, :destroy ]
  end
  resources :spots, only: [] do
    resource :spot_vote, only: [ :create, :destroy ]
  end

  namespace :my do
    resources :entries, only: [ :index ]
    resources :votes, only: [ :index ]
    resources :notifications, only: [ :index, :show ] do
      collection do
        post :mark_all_as_read
      end
    end
    resource :profile, only: [ :show, :edit, :update ]
    resource :tutorial_settings, only: [ :show, :update ]

    # Judge assignments dashboard
    resources :judge_assignments, only: [ :index, :show ] do
      resources :evaluations, only: [ :index, :show, :create, :update ], controller: "judge_evaluations"
    end
  end

  # Admin namespace
  namespace :admin do
    resource :dashboard, only: [ :show ], controller: "dashboard"
    resources :users, only: [ :index, :show, :edit, :update, :destroy ] do
      member do
        patch :suspend
        patch :unsuspend
        patch :change_role
      end
    end
    resources :contests, only: [ :index, :show, :destroy ] do
      member do
        patch :force_finish
      end
    end
    resources :categories
    resources :audit_logs, only: [ :index, :show ]
    resource :tutorial_analytics, only: [ :show ], controller: "tutorial_analytics"
  end

  # Organizers namespace
  namespace :organizers do
    resources :terms_acceptances, only: [ :new, :create ], path: "terms"
    resource :dashboard, only: [ :show ], controller: "dashboard"
    resources :areas
    resources :contest_templates, only: [ :index, :new, :create, :destroy ]
    resources :contests do
      resources :entries, only: [ :index, :show ]
      resources :judges, only: [ :index, :create, :destroy ], controller: "contest_judges"
      resources :evaluation_criteria, except: [ :show ]
      resources :spots, except: [ :show ] do
        collection do
          patch :update_positions
        end
        member do
          get :merge
          post :merge, action: :do_merge
        end
      end
      resources :discovery_spots, only: [ :index ] do
        member do
          patch :certify
          patch :reject
        end
        collection do
          post :merge
        end
      end
      resources :discovery_challenges do
        member do
          patch :activate
          patch :finish
        end
      end
      resources :moderation, only: [ :index ] do
        member do
          patch :approve
          patch :reject
        end
      end
      resources :judge_invitations, only: [ :index, :create, :destroy ] do
        member do
          post :resend
        end
      end
      resource :judging_settings, only: [ :edit, :update ]
      resource :results, only: [], controller: "results" do
        get :preview
        post :calculate
        post :announce
      end
      resource :statistics, only: [ :show ] do
        get :export
      end
      member do
        patch :publish
        patch :finish
        patch :announce_results
      end
    end
  end

  # Judge invitation response (public)
  resources :judge_invitations, only: [ :show ], param: :id do
    member do
      post :accept
      post :decline
    end
  end

  # Tutorials API
  resources :tutorials, param: :tutorial_type, only: [ :show, :update ] do
    member do
      post :start
      post :skip
      post :reset
    end
    collection do
      get :status
      patch :settings, action: :update_settings
    end
  end

  # Feedback API
  post "/feedback/action", to: "feedback#action"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Search
  get "search", to: "search#index"

  # Email preferences (unsubscribe)
  resources :email_preferences, only: [ :show, :update ], param: :token

  # Render dynamic PWA files from app/views/pwa/*
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root path
  root "home#index"
end
