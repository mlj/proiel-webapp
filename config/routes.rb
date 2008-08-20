ActionController::Routing::Routes.draw do |map|
  map.resources :audits
  map.resources :sources
  map.resources :lemmata, :singular => 'lemma'
  map.resources :bookmarks
  map.resources :tokens, :sentences

  map.resources :annotations do |annotation|
    annotation.resource :sentence_division
    annotation.resource :alignments
    annotation.resource :morphtags
    annotation.resource :dependencies
    annotation.resource :info_status
  end

  map.resource :statistics
  map.resources :announcements
  map.resources :import_sources
  map.resources :notes

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
  map.connect 'search', :controller => 'home', :action => 'search'

  # Legacy
  map.connect 'browse/:source/:book/:chapter', :controller => 'browse', :action => 'view'
  map.connect 'browse/:source/:book/:chapter/:verse', :controller => 'browse', :action => 'view'

  map.connect ':controller/:action.:format'
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'

  # Static pages. Link to individual pages using link_to 'Help', site_path('help').
  map.site 'site/:name', :controller => 'page', :action => 'show'

  # Default page
  map.root :controller => 'browse', :action => 'view', :source => 1, :book => 1, :chapter => 1
end
