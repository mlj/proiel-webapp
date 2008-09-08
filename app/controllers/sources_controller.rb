class SourcesController < ResourceController::Base
  before_filter :is_administrator?, :except => [:index, :show]
  actions :all, :except => [:new, :create, :destroy]

  private

  def collection
    @sources = Source.search(params[:query], :page => current_page)
  end

  show.before do
    @completion_stats = {
      :reviewed => @source.sentences.reviewed.count,
      :annotated => @source.sentences.annotated.unreviewed.count,
      :unannotated => @source.sentences.unannotated.count,
    }
    @annotated_by_stats = @source.annotated_sentences.count(:group => :annotator).map { |k, v| [k.full_name, v] }
    @reviewed_by_stats = @source.reviewed_sentences.count(:group => :reviewer).map { |k, v| [k.full_name, v] }
  end
end
