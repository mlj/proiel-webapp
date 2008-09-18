class SourceDivisionsController < ResourceController::Base
  actions :all, :except => [:new, :create, :edit, :update, :destroy]

  show.before do
    @sentences = @source_division.sentences.search("", :page => current_page, :per_page => 40)

    @sentence_completion_stats = {
      :reviewed => @source_division.sentences.reviewed.count,
      :annotated => @source_division.sentences.annotated.unreviewed.count,
      :unannotated => @source_division.sentences.unannotated.count,
    }
    @text_token_completion_stats = {
      :reviewed => Token.word.count(:conditions => { :sentence_id => @source_division.sentences.reviewed }),
      :annotated => Token.word.count(:conditions => { :sentence_id => @source_division.sentences.annotated.unreviewed }),
      :unannotated => Token.word.count(:conditions => { :sentence_id => @source_division.sentences.unannotated }),
    }
    @annotated_by_stats = @source_division.sentences.annotated.count(:group => :annotator).map { |k, v| [k.full_name, v] }
    @reviewed_by_stats = @source_division.sentences.reviewed.count(:group => :reviewer).map { |k, v| [k.full_name, v] }
  end

  private

  def collection
    @source_divisions = SourceDivision.search(params[:query], :page => current_page)
  end
end
