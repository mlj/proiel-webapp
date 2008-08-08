require 'log4r'

class Task
  def initialize(name)
    @name = name
  end

  def execute!(user_name)
    user = User.find_by_login(user_name)
    raise "Unknown user name #{user_name}" unless user

    logger = Log4r::Logger.new(@name)
    logger.add Log4r::Outputter.stderr

    Token.transaction(user) { self.run!(logger) }
  end
end
