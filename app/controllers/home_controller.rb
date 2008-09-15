class HomeController < ApplicationController
  before_filter :is_annotator?, :only => [ :annotation ]
  before_filter :is_reviewer?, :except => [ :search, :help, :annotation, :index ]

  LOCATION_SEARCH_PATTERN = Regexp.new(/^\s*(\w+)\s+([A-Za-z]+)\s+(\d+)\s*$/).freeze
  ANNOTATION_SEARCH_PATTERN = Regexp.new(/^\s*(\d+)\s*$/).freeze

  def index
    # FIXME: this is called from user_controller!
    redirect_to :controller => 'browse', :action => 'view', :source => 1, :book => 1, :chapter => 1
  end

  def quick_search
    query = params[:q] || ""
    query.strip!

    if m = query.match(LOCATION_SEARCH_PATTERN) 
      # A text location
      all, source, book, chapter = m.to_a
      source += '%'
      source = Source.find(:first, :conditions => [ "code like ? or abbreviation like ?", source, source ])
      book += '%'
      book = Book.find(:first, :conditions => [ "title like ? or abbreviation like ? or code like ?", book, book, book ])

      redirect_to :controller => 'browse', :action => 'view', :source => source.id, :book => book.id, :chapter => chapter
    elsif m = query.match(ANNOTATION_SEARCH_PATTERN) 
      # A sentence ID.
      if Sentence.exists?($1)
        sentence = Sentence.find($1)
        redirect_to annotation_url(sentence)
      else
        flash[:error] = 'No such sentence ID'
        redirect_to annotations_url
      end
    else
      # A token or lemma.
      redirect_to :controller => 'home', :action => 'search', :query => query, :mode => 'tokens'
    end
  end

  def search
    params[:query] ||= ''
    params[:mode] ||= 'tokens'

    case params[:mode]
    when 'tokens'
      @tokens = Token.search(params[:query].strip, :page => current_page)
    when 'lemmata'
      @lemmata = Lemma.search(params[:query].strip, :page => current_page)
    end
  end

  def user_administration
  end

  def merge_tokens
    token = Token.find(params[:id])
    token.merge!
    redirect_to token_url(token)
  end

  def merge_lemmata
    from = Lemma.find(params[:first_id])
    to = Lemma.find(params[:second_id])
    to.merge!(from)
    redirect_to lemma_url(to)
  end
end
