ActionController::Routing::Routes.draw do |map|
  map.devise_for :users
  map.resources :users

  map.resources :audits
  map.resource :statistics
  map.resources :sources do |s|
    s.resource :statistics
  end
  map.resources :source_divisions do |s|
    s.resource :statistics
  end
  map.resources :alignments, :member => {
    :commit => :post,
    :uncommit => :post,
  }
  map.resources :lemmata, :singular => 'lemma', :member => {
    :merge => :post,
  }
  map.resources :tokens, :member => {
    :dependency_alignment_group => :get,
  }
  map.resources :parts_of_speech
  map.resources :languages

  map.resources :sentences  do |annotation|
    annotation.resource :dependency_alignments
    annotation.resource :morphtags
    annotation.resource :dependencies
    annotation.resource :info_status, :collection => {
      :delete_contrast => :post,
      :delete_prodrop => :post
    }
    annotation.resource :tokenizations
  end

  map.resources :import_sources
  map.resources :notes
  map.resources :semantic_tags
  map.resource :preferences

  # Permalinks
  map.connect 'permalinks/sentence/:id', :controller => 'annotations', :action => 'show'

  # Quick search and search suggestions
  map.connect 'search', :controller => 'home', :action => 'quick_search'
  map.connect 'search_suggestions.:format', :controller => 'home', :action => 'quick_search_suggestions'

  # Legacy
  map.connect ':controller/:action.:format'
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'

  # Static pages. Link to individual pages using link_to 'Help', site_path('help').
  map.site 'site/:name', :controller => 'page', :action => 'show'

  # Default page
  map.root :controller => 'home', :action => 'index'
end
