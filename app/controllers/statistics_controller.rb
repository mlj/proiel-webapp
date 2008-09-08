class StatisticsController < ApplicationController
  before_filter :is_annotator?

  BookCompletionRatio = Struct.new(:source, :book, :ratio)

  def show
    @completion_stats = {
      :reviewed => Sentence.reviewed.count,
      :annotated => Sentence.annotated.unreviewed.count,
      :unannotated => Sentence.unannotated.count,
    }
    @annotated_by_stats = Sentence.annotated.count(:group => :annotator).map { |k, v| [k.full_name, v] }
    @reviewed_by_stats = Sentence.reviewed.count(:group => :reviewer).map { |k, v| [k.full_name, v] }
    @activity_stats = Sentence.annotated.count(:all, :conditions => { "annotated_at" => 1.month.ago..1.day.ago },
                                               :group => "DATE_FORMAT(annotated_at, '%Y-%m-%d')",
                                               :order => "annotated_at ASC")
    @sources = Source.all

    user = User.find(session[:user_id])
    limit = 10
    @recent_annotations = Sentence.find(:all, :limit => limit, 
                               :conditions => [ 'annotated_by = ?', user ],
                               :order => 'annotated_at DESC')
    @recent_reviews = Sentence.find(:all, :limit => limit, 
                                :conditions => [ 'reviewed_by = ?', user ],
                               :order => 'reviewed_at DESC')
    @recent_reviewed = Sentence.find(:all, :limit => limit, 
                                :conditions => [ 'annotated_by = ? and reviewed_by is not null', user ],
                                :order => 'reviewed_at DESC')

    @book_completion_ratios = []
    Source.find(:all).each do |source|
      source.books.each do |book|
        @book_completion_ratios << BookCompletionRatio.new(source, book, source.book_completion_ratio(book.id))
      end
    end
  end
end
