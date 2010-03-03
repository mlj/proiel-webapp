class SourceDivisionsController < InheritedResources::Base
  actions :index, :show, :edit, :update

  before_filter :is_administrator?, :except => [:index, :show]

  def show
    @source_division = SourceDivision.find(params[:id])
    @sentences = @source_division.sentences.search("", :page => current_page, :per_page => 40)

    show!
  end

  def edit
    @source_division = SourceDivision.find(params[:id])
    @sentences = @source_division.sentences.search("", :page => current_page, :per_page => 40)

    edit!
  end

  private

  def collection
    criteria = {:title => params[:query], :source_id => params[:source] }.delete_if { |k,v| v.nil? }
    @source_divisions = SourceDivision.search(criteria, :page => current_page)
  end
end
