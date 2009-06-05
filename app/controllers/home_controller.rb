class HomeController < ApplicationController
  before_filter :is_annotator?, :only => [ :annotation ]
  before_filter :is_reviewer?, :except => [ :quick_search, :quick_search_suggestions, :search, :help, :annotation, :index ]

  LOCATION_SEARCH_PATTERN = Regexp.new(/^\s*(\w+)\s+([A-Za-z]+)\s*$/).freeze
  ANNOTATION_SEARCH_PATTERN = Regexp.new(/^\s*(\d+)\s*$/).freeze

  def index
    # FIXME: this is called from user_controller!
    redirect_to source_divisions_url
  end

  # Returns suggestions for Open Search suggestion queries.
  def quick_search_suggestions
    query = params[:q] || ""
    query.strip!

    @results =
      Token.find(:all, :conditions => [ "form LIKE ?", "#{query}%" ], :limit => 10).map(&:form) +
      Lemma.find(:all, :conditions => [ "CONCAT(lemma, variant) LIKE ?", "#{query}%" ], :limit => 10).map(&:export_form)
    @results.uniq!
    @results.sort!

    respond_to do |format|
      format.html { render :partial => 'quick_search_suggestions' }
      format.js { render :json => [query, @results].to_json }
    end
  end

  def quick_search
    query = params[:q] || ""
    query.strip!

    if m = query.match(LOCATION_SEARCH_PATTERN) 
      all, source, book = m.to_a
      source = Source.find(:first, :conditions => [ "code like ? or abbreviation like ?", "#{source}%", "#{source}%" ])
      d = source.source_divisions.find(:first, :conditions => [ "title LIKE ? OR abbreviated_title LIKE ?", "#{book}%", "#{book}%" ])
      if d
        redirect_to source_division_url(d)
      else
        redirect_to source_divisions_url
      end
    elsif m = query.match(ANNOTATION_SEARCH_PATTERN)
      redirect_to annotation_url($1)
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

  def merge_lemmata
    from = Lemma.find(params[:first_id])
    to = Lemma.find(params[:second_id])
    to.merge!(from)
    redirect_to lemma_url(to)
  end
end
