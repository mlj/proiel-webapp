require 'log4r'

def execute_job(user_name, source_code, name, parameters, audited = true)
  user = User.find_by_login(user_name)
  raise "Unknown user name #{user_name}" unless user

  if source_code
    source = Source.find_by_code(source_code)
    raise "Unknown source code #{source_code}" unless source
  end

  logger = Log4r::Logger.new(name)
  logger.add Log4r::Outputter.stderr
  log_string = StringIO.new
  logger.add Log4r::IOOutputter.new('job', log_string)

  job = Job.schedule!(user.id, source ? source.id : nil, name, parameters.length > 0 ? parameters : nil, audited)
  begin
    trap("SIGINT") { job.finish!(:aborted) }

    job.start!

    #FIXME: this interacts with acts_as_audited
    if audited
      Thread.current['job_id'] = job.id
    else
      Sentence.disable_auditing
      Token.disable_auditing
    end

    yield(logger, job)
  rescue Exception => e
    job.finish!(:failed)
    raise e
  else
    job.finish!
  end

  logger.remove('job')
  log_string.rewind
  l = log_string.read
  if l.length < 65536 # truncate too long logs
    job.log = l
    job.save!
  end
end
