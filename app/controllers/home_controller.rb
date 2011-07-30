class HomeController < ApplicationController
  before_filter :is_annotator?, :only => [ :annotation ]
  before_filter :is_reviewer?, :except => [ :quick_search, :quick_search_suggestions, :search, :help, :annotation, :index ]

  def index
    @sources = Source.search(nil, :page => current_page)
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

    case query
    when /^\d+$/ # We're guessing this is a sentence ID
      redirect_to sentence_url(query.to_i)
    else # We're taking this to be a token
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
end
