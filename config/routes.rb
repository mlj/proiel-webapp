Proiel::Application.routes.draw do
  devise_for :users
  resources :users, :only => [:index, :show]

  resource :profile, :only => [:edit, :update]

  resources :audits, :only => [:index, :destroy]

  resource :statistics, :only => [:show]

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

  resources :dictionaries, :only => [:index, :show]

  resources :lemmata, :only => [:show, :edit, :update] do
    member do
      post :merge
    end
  end

  resources :tokens, :only => [:show, :edit, :update] do
    member do
      get :dependency_alignment_group
    end
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

    resource :morphtags, :only => [:show, :edit, :update] do
      member do
        post :auto_complete_for_morphtags_lemma
      end
    end

    resource :dependencies, :only => [:show, :edit, :update]

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

  resource :search, :only => [:show]

  # Wizard
  match '/wizard/:action', :to => 'wizard#:action'
  match '/wizard',         :to => 'wizard#index'

  # Permalinks
  match '/permalinks/sentence/:id', :to => 'annotations#show'

  # Static pages and exported files.
  resources :pages
  match '/exports/:id.:format' => 'pages#export', :as => :export, :via => :get

  # Quick search and search suggestions
  match '/quick_search', :to => 'searches#quick_search', :as => :quick_search
  match '/quick_search_suggestions.:format', :to => 'searches#quick_search_suggestions'

  # Default page
  root :to => 'sources#index'
end
