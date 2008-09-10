require 'log4r'

class Task
  def initialize(name)
    @name = name
  end

  def execute!
    logger = Log4r::Logger.new(@name)
    logger.add Log4r::Outputter.stderr

    Token.transaction { self.run!(logger) }
  end
end
