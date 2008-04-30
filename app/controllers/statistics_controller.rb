class StatisticsController < ApplicationController
  before_filter :is_reviewer?

  # GET /statistics
  def show
    @completion = Source.completion
    @sources = Source.find(:all)
    @activity = Source.activity

    roles = Role.find(:all, :conditions => { :code => [ :annotator, :reviewer, :administrator ] })
    @users = roles.collect { |role| role.users }.flatten

    t = Token.count(:all, :conditions => 'morphtag_performance is not null', :group => 'morphtag_performance')
    @tagger_performance = Hash[*t.flatten]
  end

#  def monthly
#    data_set = Ruport::DataSet.new(self.column_names)
#    self.find_all.each do |row|
#    data_set << row.attributes
  #    end
#    data_set.to_csv
#  end
end
