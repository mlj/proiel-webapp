class SourcesController < ResourceController::Base
  before_filter :is_administrator?, :except => [:index, :show]
  actions :all, :except => [:destroy]

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
      :reviewed => Sentence.by_source(@source).reviewed.count,
      :annotated => Sentence.by_source(@source).annotated.unreviewed.count,
      :unannotated => Sentence.by_source(@source).unannotated.count,
    }
    @text_token_completion_stats = {
      :reviewed => Token.word.count(:conditions => { :sentence_id => Sentence.by_source(@source).reviewed }),
      :annotated => Token.word.count(:conditions => { :sentence_id => Sentence.by_source(@source).annotated.unreviewed }),
      :unannotated => Token.word.count(:conditions => { :sentence_id => Sentence.by_source(@source).unannotated }),
    }
    @annotated_by_stats = Sentence.by_source(@source).annotated.count(:group => :annotator).map { |k, v| [k.full_name, v] }
    @reviewed_by_stats = Sentence.by_source(@source).reviewed.count(:group => :reviewer).map { |k, v| [k.full_name, v] }
  end
end
