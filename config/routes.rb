ActionController::Routing::Routes.draw do |map|
  map.resources :audits
  map.resources :sources, :source_divisions
  map.resources :alignments, :member => {
    :commit => :post,
    :uncommit => :post,
  }
  map.resources :lemmata, :singular => 'lemma'
  map.resources :bookmarks
  map.resources :tokens, :member => {
    :dependency_alignment_group => :get,
  }
  map.resources :sentences
  map.resources :languages

  map.resources :annotations do |annotation|
    annotation.resource :sentence_division
    annotation.resource :dependency_alignments
    annotation.resource :morphtags
    annotation.resource :dependencies
    annotation.resource :info_status, :collection => {
      :delete_contrast => :post,
      :delete_prodrop => :post
    }
  end

  map.resource :statistics
  map.resources :announcements
  map.resources :import_sources
  map.resources :notes
  map.resources :semantic_tags
  map.resource :preferences

  # Authentication and authorisation
  map.resources :users, :member => { :suspend   => :put,
                                     :unsuspend => :put,
                                     :purge     => :delete }
  map.resource :session
  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate', :activation_code => nil
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'

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
  map.root :source_divisions
end
