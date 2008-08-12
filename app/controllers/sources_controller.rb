class SourcesController < ResourceController::Base
  before_filter :is_administrator?, :except => [:index, :show]
  actions :all, :except => [:new, :create, :destroy]

  private

  def collection
    @sources = Source.search(params[:query], :page => current_page)
  end
end
