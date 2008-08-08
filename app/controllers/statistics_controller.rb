class StatisticsController < ApplicationController
  before_filter :is_annotator?

  BookCompletionRatio = Struct.new(:source, :book, :ratio)

  # GET /statistics
  def show
    @completion = Source.completion
    @sources = Source.find(:all)
    @activity = Source.activity

    all_user_activity = User.find(:all).collect { |u| UserActivity.new(u) }.select(&:is_active?)
    if current_user.has_role?(:reviewer)
      @user_activity = all_user_activity
    else
      my_activity, others_activity = all_user_activity.partition { |u| u.user == current_user }
      @user_activity = my_activity
    end

    t = Token.count(:all, :conditions => 'morphtag_performance is not null', :group => 'morphtag_performance')
    @tagger_performance = Hash[*t.flatten]

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

#  def monthly
#    data_set = Ruport::DataSet.new(self.column_names)
#    self.find_all.each do |row|
#    data_set << row.attributes
  #    end
#    data_set.to_csv
#  end
end
