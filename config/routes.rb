Rails.application.routes.draw do
  devise_for :users
  resources :users, :only => [:index, :show]

  resources :audits, :only => [:index, :destroy]

  resources :sources, :only => [:index, :show, :edit, :update]

  resources :source_divisions, :only => [:show, :edit, :update] do
    resource :discourse
  end

  resources :semantic_relations, :only => [:show, :edit, :update]

  resources :alignments, :only => [:show, :edit] do
    member do
      post :commit
      post :uncommit
    end
  end

  resources :lemmata, :only => [:index, :show, :edit, :update] do
    collection do
      get :autocomplete
    end

    member do
      post :merge
    end
  end

  resources :tokens, :only => [:index, :edit, :update] do
    member do
      get :dependency_alignment_group
    end
    get :quick_search, on: :collection
  end

  resources :sentences, :only => [:show, :edit, :update] do
    member do
      get :merge
      get :tokenize
      get :resegment_edit
      get :flag_as_not_reviewed # FIXME: should be post
      get :flag_as_reviewed     # FIXME: should be post
      get :export
      get :annotation
    end

    resource :dependency_alignments, :only => [:show, :edit, :update]

    resource :info_status, :only => [:edit, :update] do
      collection do
        post :delete_contrast
        post :delete_prodrop
      end
    end

    resource :tokenizations, :only => [:edit, :update]
  end

  resources :notes, :only => [:edit, :update, :destroy]

  resources :semantic_tags, :only => [:index, :show]

  resources :schemas, only: [:show]

  # Wizard
  get '/wizard/:action', to: 'wizard#:action'
  get '/wizard', to: 'wizard#index'

  # Quick search and search suggestions
  get '/quick_search', to: 'tokens#quick_search'
  get '/quick_search.:format', to: 'tokens#quick_search'

  # Default page
  root :to => 'sources#index'
end
