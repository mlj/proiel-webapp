class SourceDivisionsController < ResourceController::Base
  before_filter :is_administrator?, :except => [:index, :show]
  actions :all, :except => [:new, :create, :destroy]

  show.before do
    @sentences = @source_division.sentences.search("", :page => current_page, :per_page => 40)
  end

  edit.before do
    @sentences = @source_division.sentences.search("", :page => current_page, :per_page => 40)
  end

  private

  def collection
    criteria = {:title => params[:query], :source_id => params[:source] }.delete_if { |k,v| v.nil? }
    @source_divisions = SourceDivision.search(criteria, :page => current_page)
  end
end
