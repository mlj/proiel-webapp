class HomeController < ApplicationController
  before_filter :is_annotator?, :only => [ :annotation ]
  before_filter :is_reviewer?, :except => [ :search, :help, :annotation, :preferences, :index ]

  LOCATION_SEARCH_PATTERN = Regexp.new(/^\s*(\w+)\s+([A-Za-z]+)\s+(\d+)\s*$/).freeze
  ANNOTATION_SEARCH_PATTERN = Regexp.new(/^\s*(\d+)\s*$/).freeze

  def index
    # FIXME: this is called from user_controller!
    redirect_to :controller => 'browse', :action => 'view', :source => 1, :book => 1, :chapter => 1
  end

  def search
    if params[:q]
      # Simple query
      params[:tokens] = true
      params[:lemmata] = true
      params[:exact] = nil
      params[:query] = params[:q]
    else
      # Advanced query
    end

    query = params[:query] || ""
    query.strip!

    # Try to figure out what this is: first try a location lookup
    if m = query.match(LOCATION_SEARCH_PATTERN) 
      all, source, book, chapter = m.to_a
      source += '%'
      source = Source.find(:first, :conditions => [ "code like ? or abbreviation like ?", source, source ])
      book += '%'
      book = Book.find(:first, :conditions => [ "title like ? or abbreviation like ? or code like ?", book, book, book ])
      redirect_to :controller => 'browse', :action => 'view', :source => source.id, :book => book.id,
        :chapter => chapter
    elsif m = query.match(ANNOTATION_SEARCH_PATTERN) 
      # All numeric. Go to annotation page.
      if Sentence.exists?($1)
        sentence = Sentence.find($1)
        redirect_to annotation_url(sentence)
      else
        flash[:error] = 'No such sentence ID'
        redirect_to annotations_url
      end
    else
      @tokens = params[:tokens] ? Token.search({ :form => query, :exact => params[:exact] }, nil, nil) : []

      base_form, variant = query.split('#')
      @lemmata = params[:lemmata] ? Lemma.search({ :lemma => base_form, :variant => variant,
                                                   :exact => params[:exact] }, nil, 10) : [] 
    
      if @tokens.length == 0 and @lemmata.length == 0
        #FIXME
        # Present suggestions instead
      end
    end
  end

  def annotation
    @activity = Source.activity
    @completion = Source.completion

    user = session[:user]
    limit = 10
    @recent_annotations = Sentence.find(:all, :limit => limit, 
                               :conditions => [ 'annotated_by = ?', user ],
                               :order => 'annotated_at DESC')
    @recent_reviews = Sentence.find(:all, :limit => limit, 
                                :conditions => [ 'reviewed_by = ?', user ],
                               :order => 'reviewed_at DESC')
    @recent_reviewed = Sentence.find(:all, :limit => limit, 
                                :conditions => [ 'annotated_by = ? and reviewed_by is not null', user ],
                                :order => 'reviewed_at DESC')
  end

  def user_administration
  end

  def tagger
    state, pick, *suggestions = TAGGER.tag_token(params[:language], params[:form], :word, 
                                                 (params[:existing] and params[:existing] != '') ? MorphLemmaTag.new(params[:existing]) : nil)
    render :text => "result = #{state}<br>pick = #{pick}<br>suggestions = <ul>#{suggestions.collect { |s, w| "<li>tag = #{s}, weight = #{w}</li>" }}</ul>"
  end

  def tag_token_test
    if Token.exists?(params[:id]) 
      token = Token.find(params[:id])

      state, pick, *suggestions = token.invoke_tagger

      render :text => "result = #{state}<br>pick = #{pick}<br>suggestions = <ul>#{suggestions.collect { |s, w| "<li>tag = #{s}, weight = #{w}</li>" }}</ul>"
    else
      render :text => 'No such token'
    end
  end
end
