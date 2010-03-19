class StatisticsController < ApplicationController
  before_filter :is_annotator?
  before_filter :find_parents

  def show
    sentences = case @parent
                when Source
                  Sentence.by_source(@parent)
                when SourceDivision
                  @parent.sentences
                else
                  Sentence
                end

    # Grab last 10 days with activity
    activity_dates  = sentences.annotated.find(:all, :limit => 10, :group => "DATE_FORMAT(annotated_at, '%Y-%m-%d')", :order => "annotated_at ASC")
    activity_date_range = activity_dates.first.annotated_at..activity_dates.last.annotated_at

    @activity_stats = sentences.annotated.count(:all, :group => "DATE_FORMAT(annotated_at, '%Y-%m-%d')", :order => "annotated_at ASC", :conditions => { :annotated_at => activity_date_range })

    @sentence_completion_stats = {
      :reviewed => sentences.reviewed.count,
      :annotated => sentences.annotated.unreviewed.count,
      :unannotated => sentences.unannotated.count,
    }
    @annotated_by_stats = sentences.annotated.count(:group => :annotator).map { |k, v| [k.full_name, v] }
    @reviewed_by_stats = sentences.reviewed.count(:group => :reviewer).map { |k, v| [k.full_name, v] }
  end

  protected

  def find_parents
    @parent = Source.find(params[:source_id]) if params[:source_id]
    @parent = SourceDivision.find(params[:source_division_id]) if params[:source_division_id]
  end
end
