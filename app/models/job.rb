class Job < ActiveRecord::Base
  has_many :changesets, :as => :changer
  belongs_to :user
  belongs_to :source

  # Returns true if job is in progress.
  def running? 
    !finished_at? && started_at?
  end

  # Returns true if job has finished.
  def finished?
    finished_at? && started_at?
  end

  # Schedules a new job. Returns the new job.
  def self.schedule!(user_id, source_id, name, parameters = nil, audited = true)
    j = Job.create(:user_id => user_id, :source_id => source_id, 
                   :name => name, :parameters => parameters, :audited => audited)
    j.save!
    j
  end
  
  # Starts a job.
  def start!
    self.started_at = Time.now
    save!
  end

  # Finishes a job.
  def finish!(result = :successful)
    if started_at? 
      if !finished_at? 
        self.finished_at = Time.now
        self.result = result
        save!
      else
        raise "Job already finished"
      end
    else
      raise "Cannot finish a that has not been started"
    end
  end

  protected

  def self.search(search, page)
    search ||= {}
    conditions = [] 
    clauses = []

    if search[:user] and search[:user] != ''
      clauses << "user_id = ?"
      conditions << search[:user]
    end

    conditions = [clauses.join(' and ')] + conditions

    paginate(:page => page, :per_page => 50, :order => 'started_at', :conditions => conditions)
  end
end
