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
      # Simple query: Enter defaults
      params[:mode] = 'tokens'
      params[:exact] = nil
      params[:query] = params[:q]
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
      # Must be a lemma/token lookup
      case params[:mode]
      when 'tokens'
        @tokens = Token.search(params[:query], :page => current_page)
      when 'lemmata'
        @lemmata = Lemma.search(params[:query], :page => current_page)
      else
        flash[:error] = 'Invalid query'
      end
    end
  end

  def user_administration
  end

  def tagger
    state, pick, *suggestions = TAGGER.tag_token(params[:language], params[:form],
                                                 (params[:existing] and params[:existing] != '') ? PROIEL::MorphLemmaTag.new(params[:existing]) : nil)
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

  def merge_tokens
    token = Token.find(params[:id])
    versioned_transaction { token.merge! }
    redirect_to token_url(token)
  end

  def merge_lemmata
    versioned_transaction do
      from = Lemma.find(params[:first_id])
      to = Lemma.find(params[:second_id])
      to.merge!(from)
      redirect_to lemma_url(to)
    end
  end
end
