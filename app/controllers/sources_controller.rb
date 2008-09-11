class SourcesController < ResourceController::Base
  before_filter :is_administrator?, :except => [:index, :show]
  actions :all, :except => [:new, :create, :destroy]

  private

  def collection
    @sources = Source.search(params[:query], :page => current_page)
  end

  index.before do
    @sentence_completion_stats = {
      :reviewed => Sentence.reviewed.count,
      :annotated => Sentence.annotated.unreviewed.count,
      :unannotated => Sentence.unannotated.count,
    }
    @text_token_completion_stats = {
      :reviewed => Token.word.count(:conditions => { :sentence_id => Sentence.reviewed }),
      :annotated => Token.word.count(:conditions => { :sentence_id => Sentence.annotated.unreviewed }),
      :unannotated => Token.word.count(:conditions => { :sentence_id => Sentence.unannotated }),
    }
    @annotated_by_stats = Sentence.annotated.count(:group => :annotator).map { |k, v| [k.full_name, v] }
    @reviewed_by_stats = Sentence.reviewed.count(:group => :reviewer).map { |k, v| [k.full_name, v] }
  end

  show.before do
    @sentence_completion_stats = {
      :reviewed => @source.sentences.reviewed.count,
      :annotated => @source.sentences.annotated.unreviewed.count,
      :unannotated => @source.sentences.unannotated.count,
    }
    @text_token_completion_stats = {
      :reviewed => @source.tokens.word.count(:conditions => { :sentence_id => @source.sentences.reviewed }),
      :annotated => @source.tokens.word.count(:conditions => { :sentence_id => @source.sentences.annotated.unreviewed }),
      :unannotated => @source.tokens.word.count(:conditions => { :sentence_id => @source.sentences.unannotated }),
    }
    @annotated_by_stats = @source.sentences.annotated.count(:group => :annotator).map { |k, v| [k.full_name, v] }
    @reviewed_by_stats = @source.sentences.reviewed.count(:group => :reviewer).map { |k, v| [k.full_name, v] }
  end
end
