class SemanticTagsController < ResourceController::Base
  before_filter :is_reviewer?

  private

  def collection
    @semantic_tags = SemanticTag.search(params[:query], :page => current_page)
  end
end
