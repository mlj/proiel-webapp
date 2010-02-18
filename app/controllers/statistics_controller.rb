class StatisticsController < ApplicationController
  before_filter :is_annotator?

  def show
    @activity_stats = Sentence.annotated.count(:all, :conditions => { "annotated_at" => 1.month.ago..1.day.ago },
                                               :group => "DATE_FORMAT(annotated_at, '%Y-%m-%d')",
                                               :order => "annotated_at ASC")
    @sources = Source.all

    limit = 10
    @recent_annotations = Sentence.find(:all, :limit => limit, 
                               :conditions => ['annotated_by = ?', current_user],
                               :order => 'annotated_at DESC')
    @recent_reviews = Sentence.find(:all, :limit => limit, 
                                :conditions => ['reviewed_by = ?', current_user],
                               :order => 'reviewed_at DESC')
    @recent_reviewed = Sentence.find(:all, :limit => limit, 
                                :conditions => ['annotated_by = ? and reviewed_by is not null', current_user],
                                :order => 'reviewed_at DESC')
  end
end
