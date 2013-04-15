class StatisticsController < ApplicationController
  before_filter :is_annotator?

  def show
    @parent = Source.find(params[:source_id]) if params[:source_id]

    sentences = if @parent
        Sentence.by_source(@parent)
      else
        Sentence
      end

    @activity_stats = sentences.annotated.group("DATE_FORMAT(annotated_at, '%Y-%m-%d')").order('annotated_at DESC').limit(10).count

    if @parent
      @sentence_completion_stats = @parent.aggregated_status_statistics
    else
      @sentence_completion_stats = Source.aggregated_status_statistics
    end

    @annotated_by_stats = sentences.annotated.count(:group => :annotator).map { |k, v| [k.try(:full_name), v] }
    @reviewed_by_stats = sentences.reviewed.count(:group => :reviewer).map { |k, v| [k.try(:full_name), v] }
  end
end
