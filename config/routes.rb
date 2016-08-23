Rails.application.routes.draw do
  devise_for :users
  resources :users, :only => [:index, :show]

  resource :profile, :only => [:edit, :update]

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
    member do
      post :merge
    end
  end

  resources :tokens, :only => [:index, :edit, :update] do
    member do
      get :dependency_alignment_group
    end
    get :quick_search, on: :collection
    get :opensearch, on: :collection
  end

  resources :sentences, :only => [:show, :edit, :update] do
    member do
      get :merge
      get :tokenize
      get :resegment_edit
      get :flag_as_not_reviewed # FIXME: should be post
      get :flag_as_reviewed     # FIXME: should be post
      get :export
    end

    resource :dependency_alignments, :only => [:show, :edit, :update]

    resource :morphtags, :only => [:edit, :update] do
      member do
        post :auto_complete_for_morphtags_lemma
      end
    end

    resource :dependencies, :only => [:edit, :update]

    resource :info_status, :only => [:edit, :update] do
      collection do
        post :delete_contrast
        post :delete_prodrop
      end
    end

    resource :tokenizations, :only => [:edit, :update]
  end

  resources :notes, :only => [:show, :edit, :update, :destroy]

  resources :semantic_tags, :only => [:index, :show]

  match '/tags',             to: 'tags#index'
  match '/tags/:tag',        to: 'tags#index'
  match '/tags/:tag/:value', to: 'tags#index'

  # Wizard
  get '/wizard/:action', to: 'wizard#:action'
  get '/wizard', to: 'wizard#index'

  # Quick search and search suggestions
  get '/quick_search', to: 'tokens#quick_search'
  get '/quick_search.:format', to: 'tokens#quick_search'
  get '/opensearch.:format', to: 'tokens#opensearch'

  # Default page
  root :to => 'sources#index'
end
