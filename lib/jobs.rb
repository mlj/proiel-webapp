require 'log4r'

class Task
  def initialize(name, read_only = false, audited = true)
    @name = name
    @read_only = read_only
    @audited = true
  end

  def execute!(user_name)
    unless @read_only
      user = User.find_by_login(user_name)
      raise "Unknown user name #{user_name}" unless user
    end

    logger = Log4r::Logger.new(@name)
    logger.add Log4r::Outputter.stderr
    log_string = StringIO.new
    logger.add Log4r::IOOutputter.new('job', log_string)

    unless @read_only
      job = Job.schedule!(user.id, nil, @name, nil, true) 
      begin
        trap("SIGINT") { job.finish!(:aborted) }

        job.start!

        #FIXME: this interacts with acts_as_audited
        if @audited
          Thread.current['job_id'] = job.id
        else
          Sentence.disable_auditing
          Token.disable_auditing
        end

        self.run!(logger)
      rescue Exception => e
        job.finish!(:failed)
        raise e
      else
        job.finish!
      end
    else
      self.run!(logger)
    end

    logger.remove('job')
    log_string.rewind

    unless @read_only
      l = log_string.read
      if l.length < 65536 # truncate too long logs
        job.log = l
        job.save!
      end
    end
  end
end
