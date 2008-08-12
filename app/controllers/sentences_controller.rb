class SentencesController < ReadOnlyController
  before_filter :find_parents

  protected

  def find_parents
    @parent = @source = Source.find(params[:source_id]) if params[:source_id]
  end

  private
  
  def collection
    @sentences = (@parent ? @parent.sentences : Sentence).search(params[:query], :page => current_page)
  end
end
